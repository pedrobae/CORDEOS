import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider extends ChangeNotifier {
  // State management
  String? _error;

  String? get error => _error;

  Future<void> grantAdminRole(String userEmail) async {
    try {
      // First, force refresh the current user's token to get latest claims
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não está autenticado');
      }

      if (kDebugMode) {
        print('Current user UID: ${currentUser.uid}');
        print('Attempting to grant admin to email: $userEmail');
      }

      // Force refresh the ID token to get latest claims
      final idTokenResult = await currentUser.getIdTokenResult(true);
      final isCurrentUserAdmin = idTokenResult.claims?['admin'] == true;

      if (kDebugMode) {
        print('Current user admin status: $isCurrentUserAdmin');
        print('Current user claims: ${idTokenResult.claims}');
      }

      if (!isCurrentUserAdmin) {
        throw Exception(
          'Usuário atual não possui privilégios de administrador',
        );
      }

      // Call the Cloud Function with email instead of UID
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('grantAdminRole');

      if (kDebugMode) {
        print('Calling Cloud Function with data: {email: $userEmail}');
      }

      final result = await callable.call({'email': userEmail});

      if (kDebugMode) {
        print('Admin granted: ${result.data['message']}');
        print('Granted to UID: ${result.data['uid']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error granting admin: $e');
      }
      rethrow;
    }
  }
}
