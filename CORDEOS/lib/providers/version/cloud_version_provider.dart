import 'dart:async';

import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/repositories/cloud/version_repository.dart';
import 'package:cordeos/repositories/local/version_repository.dart';
import 'package:cordeos/services/key_recognizer_service.dart';
import 'package:flutter/foundation.dart';

class CloudVersionProvider extends ChangeNotifier {
  final CloudVersionRepository _repo = CloudVersionRepository();
  final LocalVersionRepository _localRepo = LocalVersionRepository();
  final _recognizer = KeyRecognizerService();

  final Map<String, VersionDto> _versions =
      {}; // Cached cloud versions firebaseID -> Version
  final Map<String, Map<int, CloudVersionNote>> _notes =
      {}; // Cached cloud versions firebaseID -> Note
  final Map<String, String> _overwriteKeys =
      {}; // Cached cloud versions firebaseID -> Key

  bool _isSaving = false;
  bool _isLoading = false;
  final Map<String, bool> _isDownloading = {}; // versionID -> isDownloading
  String? _currentLoadingOperation;
  DateTime? _loadingStartedAt;

  String _searchTerm = '';

  String? _error;

  // ===== GETTERS =====
  Map<String, VersionDto> get versions => _versions;

  VersionDto? getVersion(String firebaseId) {
    return _versions[firebaseId];
  }

  Map<String, String> get filteredCloudVersionIds {
    if (_searchTerm.isEmpty) {
      return _versions.map((id, version) => MapEntry(id, version.title));
    } else {
      final Map<String, String> tempMap = {};
      for (var entry in _versions.entries) {
        if (entry.value.title.toLowerCase().contains(_searchTerm) ||
            entry.value.author.toLowerCase().contains(_searchTerm) ||
            entry.value.tags.any(
              (tag) => tag.toLowerCase().contains(_searchTerm),
            )) {
          tempMap[entry.key] = entry.value.title;
        }
      }
      return tempMap;
    }
  }

  List<int> getSongStructure(String versionID) {
    final version = _versions[versionID];
    if (version != null) {
      return version.songStructure;
    } else {
      return [];
    }
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get currentLoadingOperation => _currentLoadingOperation;
  DateTime? get loadingStartedAt => _loadingStartedAt;
  String? get error => _error;
  bool isDownloading(String versionID) => _isDownloading[versionID] ?? false;

  Future<T> _withTimeout<T>(
    Future<T> operation,
    String operationName, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await operation.timeout(timeout);
    } on TimeoutException {
      throw TimeoutException(
        '$operationName timed out after ${timeout.inSeconds}s',
      );
    }
  }

  void _startLoading(String operationName) {
    _isLoading = true;
    _currentLoadingOperation = operationName;
    _loadingStartedAt = DateTime.now();
    _error = null;
    notifyListeners();
  }

  void _finishLoading() {
    _isLoading = false;
    _currentLoadingOperation = null;
    _loadingStartedAt = null;
    notifyListeners();
  }

  // ===== CREATE =====
  /// Persist the version dto object to the firestore db
  /// Returns the firestore ID string, created or updated
  Future<String?> saveVersion(VersionDto version) async {
    String? firestoreID;
    if (_isSaving) return firestoreID;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      if (version.firebaseId == null || version.firebaseId!.isEmpty) {
        firestoreID = await _repo.publishPublicVersion(version);
      } else {
        await _repo.updatePublicVersion(version);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error publishing public version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    return firestoreID;
  }

  // ===== READ =====
  /// Loads public versions from Firestore
  Future<void> loadVersions({
    bool forceReload = false,
    List<Cipher> localCiphers = const [],
  }) async {
    if (_isLoading && !forceReload) return;

    _startLoading('loadVersions');

    try {
      _versions.clear();
      final cloudVersions = await _withTimeout(
        _repo.getPublicVersions(forceReload: forceReload),
        'getPublicVersions',
      );

      for (var version in cloudVersions) {
        if (version.originalKey.isEmpty) {
          final recognizedKey = await _withTimeout(
            _recognizer.recognizeKeyCloud(version),
            'recognizeKeyCloud(${version.firebaseId ?? version.title})',
            timeout: const Duration(seconds: 8),
          );
          version = version.copyWith(originalKey: recognizedKey);
        }
        if (localCiphers.any(
          (cipher) =>
              cipher.title == version.title && cipher.author == version.author,
        )) {
          continue; // Skip versions whose ciphers are already in local cache
        }
        _versions[version.firebaseId!] = version;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading cloud versions: $e');
      }
    } finally {
      _finishLoading();
    }
  }

  Future<void> ensureVersionIsLoaded(String firebaseId) async {
    if (_versions.containsKey(firebaseId)) {
      return;
    }

    _startLoading('ensureVersionIsLoaded:$firebaseId');

    try {
      VersionDto? version = await _withTimeout(
        _repo.getUserVersionById(firebaseId),
        'getUserVersionById($firebaseId)',
      );
      if (version != null) {
        if (version.originalKey.isEmpty) {
          final recognizedKey = await _withTimeout(
            _recognizer.recognizeKeyCloud(version),
            'recognizeKeyCloud($firebaseId)',
            timeout: const Duration(seconds: 8),
          );
          version = version.copyWith(originalKey: recognizedKey);
        }
        _versions[firebaseId] = version;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error ensuring cloud version in cache: $e');
      }
    } finally {
      _finishLoading();
    }
  }

  // ===== UPDATE =====

  // ===== DELETE =====
  void removeVersion(String versionID) {
    _versions.remove(versionID);
    notifyListeners();
  }

  // ===== HELPER METHODS =====
  void clearCache() {
    _versions.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _currentLoadingOperation = null;
    _loadingStartedAt = null;
    _searchTerm = '';

    notifyListeners();
  }

  void toggleIsDownloading(String versionID) {
    _isDownloading[versionID] = !isDownloading(versionID);
    notifyListeners();
  }

  /// Search cached cloud versions
  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }

  // ============= LOCAL NOTES =================
  Future<int> create(
    int position,
    String content,
    String title,
    String firebaseVersionID,
  ) async {
    final note = CloudVersionNote(
      title: title,
      id: -1,
      position: position,
      content: content,
      firebaseVersionID: firebaseVersionID,
    );
    final id = await _localRepo.createNote(note);
    await _localRepo.updateNote(id, note.copyWith(id: id));
    _notes[firebaseVersionID] ??= {};
    _notes[firebaseVersionID]![id] = note;
    notifyListeners();
    return id;
  }

  // READ
  Map<int, CloudVersionNote> getNotesOfVersion(String cloudVersionFirebaseID) {
    return _notes[cloudVersionFirebaseID] ?? {};
  }

  Future<void> loadNotes() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _notes.clear();
      _notes.addAll(await _localRepo.getNotes());
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading version notes: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureVersionNotesAreLoaded(String firebaseID) async {
    if (_notes[firebaseID] != null) return;
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();
    try {
      final notes = await _localRepo.getNotesOfVersion(firebaseID);
      _notes[firebaseID] = notes;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading version notes: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE
  Future<void> update(int id, CloudVersionNote note) async {
    await _localRepo.updateNote(id, note);
  }

  // DELETE
  Future<void> delete(String firebaseID, int id) async {
    _notes[firebaseID]!.remove(id);
    notifyListeners();
    await _localRepo.deleteNote(id);
  }

  // ============= OVERWRITE KEY =================
  Future<void> saveKey(String key, String firebaseVersionID) async {
    _overwriteKeys[firebaseVersionID] = key;
    await _localRepo.saveKey(key, firebaseVersionID);
    notifyListeners();
  }

  Future<void> loadOverwriteKeys() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();
    try {
      _overwriteKeys.addAll(await _localRepo.loadOverwriteKeys());
    } catch (e) {
      _error = e.toString();
      debugPrint("CLOUD VERSION PROVIDER - error loading overwrite keys");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureOverwriteKeyIsLoaded(String firebaseVersionID) async {
    if (_overwriteKeys[firebaseVersionID] != null) return;
    final key = await _localRepo.loadOverwriteKeyOfVersion(firebaseVersionID);
    if (key != null) _overwriteKeys[firebaseVersionID] = key;
    notifyListeners();
  }

  String? checkOverwriteKey(String firebaseVersionID) {
    return _overwriteKeys[firebaseVersionID];
  }
}
