import 'package:cloud_functions/cloud_functions.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:flutter/foundation.dart';

/// Holds localized email strings to avoid context dependency in async operations.
class EmailStrings {
  final String Function(String username) invitationGreeting;
  final String Function(String scheduleName, String role) invitationMessage;
  final String Function(String shareCode) instructions;
  final String contactSupport;
  final String bestRegards;
  final String Function(String scheduleName, String role) invitationSubject;

  EmailStrings({
    required this.invitationGreeting,
    required this.invitationMessage,
    required this.instructions,
    required this.contactSupport,
    required this.bestRegards,
    required this.invitationSubject,
  });
}

class EmailProvider extends ChangeNotifier {
  static const String _functionsRegion = 'us-central1';

  // State management
  String? _error;
  bool _isSending = false;

  String? get error => _error;
  bool get isSending => _isSending;

  /// Sends invitation emails for the given schedule to users with the selected roles.
  /// 
  /// The [emailStrings] parameter should contain all localized email strings.
  /// Flutter handles localization, server only validates and sends.
  /// This prevents context invalidation errors in async operations.
  ///
  /// Returns true if emails were sent successfully, false otherwise.
  Future<bool> sendInvites(
    Schedule schedule,
    List<String> selectedRoles,
    EmailStrings emailStrings,
  ) async {
    try {
      _isSending = true;
      _error = null;
      notifyListeners();

      final functions = FirebaseFunctions.instanceFor(
        region: _functionsRegion,
      );
      final sendInviteEmail = functions.httpsCallable('sendInviteEmail');

      int successCount = 0;
      int failureCount = 0;

      for (var role in schedule.roles.values) {
        if (selectedRoles.contains(role.name)) {
          for (var user in role.users) {
            try {
              debugPrint(
                '[EmailProvider] Sending invite to ${user.email} for role ${role.name}',
              );

              // Build HTML with proper HTML escaping for user data
              final greeting = _escapeHtml(emailStrings.invitationGreeting(user.username));
              final message = _escapeHtml(
                emailStrings.invitationMessage(schedule.name, role.name),
              );
              final instructions = _escapeHtml(emailStrings.instructions(schedule.shareCode));
              final support = _escapeHtml(emailStrings.contactSupport);
              final regards = _escapeHtml(emailStrings.bestRegards);

              final htmlString = '''
                <p>$greeting</p>
                <p>$message</p>
                <p>$instructions</p>
                <p>$support</p>
                <p>${regards.replaceAll('\n', '<br>')}</p>
              ''';

              // Build subject line with localized text
              final subject = emailStrings.invitationSubject(schedule.name, role.name);

              await sendInviteEmail.call({
                'email': user.email,
                'roleName': role.name,
                'scheduleTitle': schedule.name,
                'subject': subject,
                'emailHtml': htmlString,
              });
              successCount++;
              debugPrint(
                '[EmailProvider] Successfully sent invitation to ${user.email} for role ${role.name}',
              );
            } catch (e) {
              failureCount++;
              debugPrint(
                '[EmailProvider] FAILED to send email to ${user.email}',
              );
              debugPrint('[EmailProvider] Error type: ${e.runtimeType}');
              debugPrint('[EmailProvider] Error message: $e');
              if (e is FirebaseFunctionsException) {
                debugPrint(
                  '[EmailProvider] Firebase error code: ${e.code}',
                );
                debugPrint(
                  '[EmailProvider] Firebase error details: ${e.details}',
                );
                debugPrint(
                  '[EmailProvider] Firebase error message: ${e.message}',
                );
              }
            }
          }
        }
      }

      _isSending = false;

      if (failureCount > 0) {
        _error =
            'Failed to send $failureCount invitation(s). Sent $successCount successfully.';
      }

      notifyListeners();
      return failureCount == 0;
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      debugPrint('Error in sendInvites: $e');
      return false;
    }
  }

  /// Escapes HTML special characters to prevent XSS attacks.
  /// Converts user data safely for inclusion in HTML emails.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
