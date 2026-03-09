// firebase deploy --only functions
// npm run lint -- --fix

const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall} = require("firebase-functions/v2/https");
const {beforeUserCreated} = require("firebase-functions/v2/identity");
const {auth} = require("firebase-functions/v1");

setGlobalOptions({maxInstances: 5});

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
const {SecretManagerServiceClient} = require("@google-cloud/secret-manager");
const sanitizeHtml = require("sanitize-html");

admin.initializeApp();

// Secret caching to reduce Secret Manager calls
const secretCache = new Map();
const CACHE_TTL_MS = 3600000; // 1 hour

// Helper function to retrieve secrets from Secret Manager with caching
async function getSecret(secretName) {
  const cached = secretCache.get(secretName);
  if (cached && cached.expires > Date.now()) {
    return cached.value;
  }

  const client = new SecretManagerServiceClient();
  const projectId = process.env.GCLOUD_PROJECT;
  const name = `projects/${projectId}/secrets/${secretName}/versions/latest`;

  try {
    const [version] = await client.accessSecretVersion({name});
    const value = version.payload.data.toString("utf8");
    secretCache.set(secretName, {value, expires: Date.now() + CACHE_TTL_MS});
    return value;
  } catch (error) {
    console.error(`Error accessing secret ${secretName}:`, error);
    throw error;
  }
}

// Audit logging helper
async function auditLog(action, details) {
  try {
    await admin.firestore().collection("audit_logs").add({
      action,
      ...details,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      environment: process.env.FIREBASE_CONFIG ? "production" : "development",
    });
  } catch (error) {
    console.error("Audit log failed:", error);
    // Don't throw - audit failure shouldn't block operations
  }
}


// === ADMIN FUNCTIONS ===
/// Grant admin privileges to a user by email (admin-only)
exports.grantAdminRole = onCall(async (request) => {
  // Only existing admins can grant admin role
  if (!request.auth || !request.auth.token.admin) {
    await auditLog("admin_grant_attempt_denied", {
      attemptedBy: request.auth?.uid || "unauthenticated",
      reason: "unauthorized",
    });
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can grant admin role.",
    );
  }

  const {email} = request.data;

  if (!email || typeof email !== "string" || email.length > 254) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Valid email is required.",
    );
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(userRecord.uid, {admin: true});

    await auditLog("admin_role_granted", {
      grantedTo: email,
      grantedBy: request.auth.uid,
      targetUid: userRecord.uid,
    });

    return {
      message: "Admin role granted successfully.",
      success: true,
      uid: userRecord.uid,
    };
  } catch (error) {
    console.error("Error in grantAdminRole:", error);
    // Don't leak whether user exists
    throw new functions.https.HttpsError(
        "not-found",
        "User not found or unable to grant role.",
    );
  }
});

/// Bootstrap function to grant first admin (run once, requires secret)
/// After first admin created, this endpoint becomes disabled
exports.grantFirstAdmin = functions.https.onRequest(async (req, res) => {
  // Only allow POST
  if (req.method !== "POST") {
    return res.status(405).json({error: "Method not allowed"});
  }

  try {
    // Check if any admins already exist (single-use protection)
    const adminUsers = await admin.auth().listUsers(1);
    let hasAdmin = false;
    for (const user of adminUsers.users) {
      if (user.customClaims?.admin) {
        hasAdmin = true;
        break;
      }
    }

    if (hasAdmin) {
      return res.status(403).json({error: "Bootstrap already completed. Use grantAdminRole instead."});
    }

    const {email, secret} = req.body;

    if (!email || typeof email !== "string") {
      return res.status(400).json({error: "Email required"});
    }
    if (!secret || typeof secret !== "string") {
      return res.status(400).json({error: "Secret required"});
    }

    // Verify secret from Secret Manager (not hardcoded)
    const adminSecret = await getSecret("ADMIN_BOOTSTRAP_SECRET");
    if (secret !== adminSecret) {
      await auditLog("bootstrap_secret_mismatch", {
        attemptedEmail: email,
        ip: req.ip,
      });
      return res.status(403).json({error: "Invalid secret"});
    }

    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, {admin: true});

    await auditLog("bootstrap_admin_created", {
      adminEmail: email,
      adminUid: user.uid,
    });

    return res.json({
      message: "Bootstrap complete. First admin created.",
      uid: user.uid,
      success: true,
    });
  } catch (error) {
    console.error("Bootstrap error:", error);
    // Don't expose error details
    return res.status(500).json({error: "Bootstrap failed"});
  }
});

/// Revoke admin role (with safeguards)
exports.revokeAdminRole = functions.https.onCall(async (request) => {
  if (!request.auth || !request.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can revoke admin role.",
    );
  }

  const {uid} = request.data;

  // Prevent admin from revoking their own role
  if (request.auth.uid === uid) {
    await auditLog("admin_self_revoke_attempt", {
      attemptedBy: request.auth.uid,
    });
    throw new functions.https.HttpsError(
        "permission-denied",
        "Cannot revoke your own admin role.",
    );
  }

  if (!uid || typeof uid !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Valid user ID is required.",
    );
  }

  try {
    await admin.auth().setCustomUserClaims(uid, {admin: false});

    await auditLog("admin_role_revoked", {
      revokedFrom: uid,
      revokedBy: request.auth.uid,
    });

    return {
      message: "Admin role revoked successfully.",
      success: true,
    };
  } catch (error) {
    console.error("Error in revokeAdminRole:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to revoke admin role",
    );
  }
});


// === USER ===
/// Create user document in Firestore when a new user signs up
exports.createUserDocument = beforeUserCreated(async (event) => {
  const {uid, email, displayName} = event.data;

  // Validate displayName length
  if (displayName && displayName.length > 255) {
    console.warn(`DisplayName too long for user ${uid}, truncating`);
  }

  try {
    await admin.firestore().collection("users").doc(uid).set({
      uid: uid,
      email: email || "",
      username: (displayName || "").slice(0, 255),  // Enforce max length
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User document created for ${uid}`);
    return {success: true};
  } catch (error) {
    console.error("Error creating user document:", error);
    // Don't throw - beforeUserCreated can't throw HttpsError
    return {success: false, error: error.message};
  }
});


/// Cleanup user-related data after Firebase Auth account deletion
exports.cleanSchedulesOfUser = auth.user().onDelete(async (user) => {
  const {uid, email} = user;

  try {
    // Remove user profile document if it exists.
    await admin.firestore().collection("users").doc(uid).delete();

    // Delete schedules where the user is the owner
    const schedulesSnap = await admin.firestore().collection("schedules")
        .where("owner", "==", uid)
        .get();

    const batch = admin.firestore().batch();
    schedulesSnap.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Remove user from collaborators in schedules they are part of
    const collaboratorSnap = await admin.firestore().collection("schedules")
        .where("collaborators", "array-contains", uid)
        .get();

    const collaboratorBatch = admin.firestore().batch();
    collaboratorSnap.forEach((doc) => {
      collaboratorBatch.update(doc.ref, {
        collaborators: admin.firestore.FieldValue.arrayRemove(uid),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await collaboratorBatch.commit();

    await auditLog("user_deleted_cleanup_success", {
      uid,
      email: email || "",
    });

    return null;
  } catch (error) {
    console.error("Error cleaning up deleted user data:", error);

    await auditLog("user_deleted_cleanup_failed", {
      uid,
      email: email || "",
      error: error.message || "unknown",
    });

    throw error;
  }
});

// === PLAYLIST SHARING ===

// Callable function to join a schedule using a share code
exports.joinScheduleWithCode = onCall(async (request) => {
  // Authentication required
  if (!request.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to join a schedule.",
    );
  }

  const {shareCode} = request.data;
  const userId = request.auth.uid;

  if (!shareCode || typeof shareCode !== "string" || shareCode.length > 100) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Valid share code is required.",
    );
  }

  try {
    const db = admin.firestore();

    // Query with limit to prevent reading too many documents
    const scheduleSnap = await db.collection("schedules")
        .where("shareCode", "==", shareCode)
        .limit(1)
        .get();

    if (scheduleSnap.empty) {
      await auditLog("schedule_join_invalid_code", {
        userId,
        shareCode: shareCode.slice(0, 5) + "...",  // Log partial code
      });
      throw new functions.https.HttpsError(
          "not-found",
          "Invalid or expired share code.",
      );
    }

    const scheduleDoc = scheduleSnap.docs[0];
    const scheduleId = scheduleDoc.id;
    const scheduleData = scheduleDoc.data();

    // Check if user is already a collaborator
    const currentCollaborators = scheduleData.collaborators || [];
    if (currentCollaborators.includes(userId)) {
      throw new functions.https.HttpsError(
          "already-exists",
          "You are already a collaborator on this schedule.",
      );
    }

    // Add user as collaborator
    await db.collection("schedules").doc(scheduleId).update({
      collaborators: admin.firestore.FieldValue.arrayUnion(userId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await auditLog("schedule_joined", {
      userId,
      scheduleId,
    });

    return {
      success: true,
      message: "Successfully joined schedule",
      scheduleId: scheduleId,
    };
  } catch (error) {
    console.error("Error in joinScheduleWithCode:", error);

    // Re-throw if already an HttpsError
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
        "internal",
        "Failed to join schedule",
    );
  }
});

// === EMAIL INVITATIONS ===
// Send invitation emails to users for a schedule
exports.sendInviteEmail = onCall(async (request) => {
  // Authentication required
  if (!request.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to send invites.",
    );
  }

  const {email, roleName, scheduleTitle, emailHtml, subject} = request.data;

  // Validate all required fields
  if (!email || !roleName || !scheduleTitle || !emailHtml || !subject) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "All fields required: email, roleName, scheduleTitle, subject, emailHtml.",
    );
  }

  // Strict email validation
  const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
  if (!emailRegex.test(email)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid email format.",
    );
  }

  // Validate input string lengths
  if (email.length > 254) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Email too long.",
    );
  }
  if (roleName.length > 100) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Role name too long.",
    );
  }
  if (scheduleTitle.length > 200) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Schedule title too long.",
    );
  }
  if (subject.length > 200) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Subject too long.",
    );
  }
  if (emailHtml.length > 50000) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Email content too large.",
    );
  }

  // Sanitize subject line
  const sanitizedSubject = subject
      .replace(/[\r\n]/g, "")
      .replace(/<[^>]*>/g, "")
      .slice(0, 200);

  // Sanitize HTML content
  const cleanHtml = sanitizeHtml(emailHtml, {
    allowedTags: ["p", "br", "strong", "em", "a", "ul", "ol", "li"],
    allowedAttributes: {
      a: ["href"],
    },
    allowedSchemes: ["http", "https", "mailto"],
    disallowedTagsMode: "discard",
  });

  try {
    // Use cached secrets (1 hour TTL)
    const emailUser = await getSecret("EMAIL_USER");
    const emailPassword = await getSecret("EMAIL_PASSWORD");

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: emailUser,
        pass: emailPassword,
      },
    });

    const mailOptions = {
      from: emailUser,
      to: email,
      subject: sanitizedSubject,
      html: cleanHtml,
      replyTo: emailUser,
    };

    await transporter.sendMail(mailOptions);

    await auditLog("email_invitation_sent", {
      sentBy: request.auth.uid,
      recipientEmail: email.slice(0, 5) + "...",  // Log partial email
      scheduleTitle,
    });

    return {
      success: true,
      message: "Invitation sent successfully.",
    };
  } catch (error) {
    console.error("Email send error:", error);

    await auditLog("email_invitation_failed", {
      sentBy: request.auth.uid,
      recipientEmail: email.slice(0, 5) + "...",
      error: error.code || "unknown",
    });

    // Don't expose error details
    throw new functions.https.HttpsError(
        "internal",
        "Failed to send invitation email",
    );
  }
});