import 'package:cordis/models/domain/user.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cordis/services/auth_service.dart';

class MyAuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  firebase_auth.User? _authUser;
  User? _userData;
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _authUser != null;
  String? get id => _authUser?.uid;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userName => _userData?.username;
  String? get userEmail => _userData?.email;
  String? get userCountry => _userData?.country;
  String? get userLanguage => _userData?.language;
  String? get userTimeZone => _userData?.timeZone;
  String? get photoURL => _userData?.profilePhoto;

  MyAuthProvider() {
    // Listen to auth state changes and check admin status
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(firebase_auth.User? user) {
    _authUser = user;
    _checkAdminStatus();
    notifyListeners();
  }

  Future<void> _checkAdminStatus() async {
    if (_authUser != null) {
      _isAdmin = await _authService.isAdmin;
    } else {
      _isAdmin = false;
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // Auth state change will be handled by listener
    } catch (e) {
      _error = 'Erro ao entrar: $e';
      if (kDebugMode) {
        print('Erro ao logar com email: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUpWithEmailAndPassword(email, password);
      // Auth state change will be handled by listener
    } catch (e) {
      _error = 'Erro ao criar conta: $e';
      if (kDebugMode) {
        print('Erro ao criar conta com email: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAnonymously() async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInAnonimously();
      // Auth state change will be handled by listener
    } catch (e) {
      _error = 'Erro ao entrar anonimamente: $e';
      if (kDebugMode) {
        print('Erro ao logar anonimamente: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      // Auth state change will be handled by listener
    } catch (e) {
      _error = 'Erro ao entrar com Google: $e';
      if (kDebugMode) {
        print('Erro ao logar com Google: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password for given email
  Future<void> sendPasswordResetEmail(String email) async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _error = 'Erro ao enviar email de recuperação: $e';
      if (kDebugMode) {
        print('Erro ao enviar email de recuperação: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      // Auth state change will be handled by listener
    } catch (e) {
      _error = 'Erro ao sair: $e';
      if (kDebugMode) {
        print('Erro ao deslogar: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reauthenticate(String email, String password) async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.reauthenticate(email, password);
    } catch (e) {
      _error = 'Erro ao reautenticar: $e';
      if (kDebugMode) {
        print('Erro ao reautenticar: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount();
    } catch (e) {
      _error = 'Erro ao solicitar exclusão de conta: $e';
      if (kDebugMode) {
        print('Erro ao solicitar exclusão de conta: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    if (isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword);
    } catch (e) {
      _error = 'Erro ao atualizar senha: $e';
      if (kDebugMode) {
        print('Erro ao atualizar senha: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setUserData(User user) {
    _userData = user;
    notifyListeners();
  }
}
