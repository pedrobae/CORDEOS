import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Maps Firebase error codes to user-friendly localized messages
class FirebaseErrorMapper {
  /// Maps a Firebase exception to a localized error message
  static String mapErrorToUserMessage(BuildContext context, dynamic exception) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return 'An error occurred. Please try again.';
    }

    // Handle FirebaseFunctionsException
    if (exception is FirebaseFunctionsException) {
      return _mapFunctionsError(l10n, exception);
    }

    // Handle FirebaseException
    if (exception is FirebaseException) {
      return _mapFirebaseError(l10n, exception);
    }

    // Handle generic exceptions
    return l10n.errorGeneric;
  }

  /// Maps FirebaseFunctionsException error codes to localized messages
  static String _mapFunctionsError(
    AppLocalizations l10n,
    FirebaseFunctionsException exception,
  ) {
    final code = exception.code;

    switch (code) {
      case 'already-exists':
        return l10n.errorAlreadyCollaborator;
      case 'not-found':
        return l10n.errorShareCodeInvalid;
      case 'failed-precondition':
      case 'permission-denied':
        return l10n.errorJoiningSchedule;
      case 'unauthenticated':
        return l10n.errorUnauthenticatedJoin;
      default:
        return l10n.errorJoiningSchedule;
    }
  }

  /// Maps FirebaseException error codes to localized messages
  static String _mapFirebaseError(
    AppLocalizations l10n,
    FirebaseException exception,
  ) {
    final code = exception.code;

    switch (code) {
      case 'not-found':
        return l10n.errorScheduleNotFound;
      case 'unavailable':
        return l10n.errorServiceUnavailable;
      case 'unauthenticated':
        return l10n.errorUnauthenticatedJoin;
      default:
        return l10n.errorJoiningSchedule;
    }
  }
}
