import 'dart:async';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/models/dtos/user_dto.dart';
import 'package:cordis/repositories/local/user_repository.dart';
import 'package:cordis/repositories/cloud/user_repository.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _localUserRepository = UserRepository();
  final CloudUserRepository _cloudUserRepository = CloudUserRepository();

  UserProvider();

  List<User> _knownUsers = [];

  String? _error;

  bool _hasInitialized = false;

  bool _isLoading = false;
  bool _isLoadingCloud = false;

  bool _isSaving = false;

  // Getters
  List<User> get knownUsers => _knownUsers;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;
  bool get isLoading => _isLoading;
  bool get isLoadingCloud => _isLoadingCloud;
  bool get isSaving => _isSaving;

  // ===== CREATE =====
  /// Downloads users from Firebase
  /// Saves them to local SQLite db
  Future<void> downloadUserFromCloud(String firebaseUserId) async {
    if (_isLoadingCloud) return;

    _isLoadingCloud = true;
    _error = null;
    notifyListeners();

    try {
      final userDto = await _cloudUserRepository.fetchUserById(firebaseUserId);

      if (userDto != null) {
        final user = userDto.toDomain();
        final userId = await _localUserRepository.createUser(user);
        _knownUsers.add(user.copyWith(id: userId));

        if (kDebugMode) {
          print('Downloaded and saved user: ${user.username}');
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error downloading users from cloud: $e');
      }
    } finally {
      _isLoadingCloud = false;
      notifyListeners();
    }
  }

  /// Ensures that all users in the provided list of Firebase IDs exist locally
  /// Downloads any missing users from the cloud
  Future<void> ensureUserExists(String firebaseUserId) async {
    final user = await _localUserRepository.getUserByFirebaseId(firebaseUserId);

    if (user == null) {
      await downloadUserFromCloud(firebaseUserId);
    }
  }

  Future<User> createLocalUnknownUser(String username, String email) async {
    final newUser = User(
      id: -1,
      username: username,
      email: email,
      firebaseId: null,
    );

    final userId = await _localUserRepository.createUser(newUser);
    final savedUser = newUser.copyWith(id: userId);
    _knownUsers.add(savedUser);
    notifyListeners();
    return savedUser;
  }

  // ==== READ =====
  /// Load users from local SQLite db
  Future<void> loadUsers() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _knownUsers = await _localUserRepository.getAllUsers();
      _hasInitialized = true;

      if (kDebugMode) {
        print('Loaded ${_knownUsers.length} Users from SQLite');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading ciphers: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///
  Future<UserDto?> fetchUserDtoByEmail(String email) async {
    if (_isLoading) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    UserDto? userDto;

    try {
      userDto = await _cloudUserRepository.fetchUserByEmail(email);
    } catch (e) {
      if (kDebugMode) {
        print('User with Email $email not found on firestore.');
      }
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return userDto;
  }

  int? getLocalIdByFirebaseId(String firebaseId) {
    try {
      final user = _knownUsers.firstWhere(
        (user) => user.firebaseId == firebaseId,
      );
      return user.id;
    } catch (e) {
      if (kDebugMode) {
        print('User with Firebase ID $firebaseId not found locally.');
      }
      return null;
    }
  }

  String getFirebaseIdByLocalId(int localId) {
    try {
      final user = _knownUsers.firstWhere((user) => user.id == localId);
      return user.firebaseId!;
    } catch (e) {
      if (kDebugMode) {
        print('User with local ID $localId not found locally.');
      }
      throw Exception('User with local ID $localId not found locally.');
    }
  }

  User? getUserById(int id) {
    try {
      return _knownUsers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  User? getUserByFirebaseId(String firebaseId) {
    try {
      return _knownUsers.firstWhere((user) => user.firebaseId == firebaseId);
    } catch (e) {
      return null;
    }
  }

  // ==== UPDATE =====
  Future<void> save(String firebaseId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final user = getUserByFirebaseId(firebaseId);

      if (user == null) {
        throw Exception('User with Firebase ID $firebaseId not found locally.');
      }

      final userDto = user.toDto();
      await _cloudUserRepository.update(userDto);

      await _localUserRepository.updateUser(user);

      if (kDebugMode) {
        print('Saved user ${user.username} to cloud');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error saving user data to cloud: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void cacheUsername(String firebaseId, String username) {
    final userIndex = _knownUsers.indexWhere(
      (user) => user.firebaseId == firebaseId,
    );

    if (userIndex != -1) {
      final updatedUser = _knownUsers[userIndex].copyWith(username: username);
      _knownUsers[userIndex] = updatedUser;
      notifyListeners();
    }
  }

  void cacheUserLanguage(String firebaseId, String languageCode) {
    final userIndex = _knownUsers.indexWhere(
      (user) => user.firebaseId == firebaseId,
    );

    if (userIndex != -1) {
      final updatedUser = _knownUsers[userIndex].copyWith(
        language: languageCode,
      );
      _knownUsers[userIndex] = updatedUser;
      notifyListeners();
    }
  }

  void cacheUserTimeZone(String firebaseId, String timeZone) {
    final userIndex = _knownUsers.indexWhere(
      (user) => user.firebaseId == firebaseId,
    );

    if (userIndex != -1) {
      final updatedUser = _knownUsers[userIndex].copyWith(timeZone: timeZone);
      _knownUsers[userIndex] = updatedUser;
      notifyListeners();
    }
  }

  void cacheUserCountry(String firebaseId, String country) {
    final userIndex = _knownUsers.indexWhere(
      (user) => user.firebaseId == firebaseId,
    );

    if (userIndex != -1) {
      final updatedUser = _knownUsers[userIndex].copyWith(country: country);
      _knownUsers[userIndex] = updatedUser;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  /// Deletes all user data from firestore
  Future<void> deleteUserData(String userId) async {
    try {
      await _cloudUserRepository.deleteUserById(userId);
      await _localUserRepository.deleteUser(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data from cloud: $e');
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearCache() {
    _knownUsers = [];
    _error = null;
    _hasInitialized = false;
    _isLoading = false;
    _isLoadingCloud = false;
    notifyListeners();
  }
}
