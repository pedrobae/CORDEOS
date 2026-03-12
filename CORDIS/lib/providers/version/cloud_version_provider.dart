import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/repositories/cloud/version_repository.dart';
import 'package:cordis/services/key_recognizer_service.dart';
import 'package:flutter/foundation.dart';

class CloudVersionProvider extends ChangeNotifier {
  final CloudVersionRepository _repo = CloudVersionRepository();
  final _recognizer = KeyRecognizerService();

  final Map<String, VersionDto> _versions =
      {}; // Cached cloud versions firebaseID -> Version

  bool _isSaving = false;
  bool _isLoading = false;
  final Map<String, bool> _isDownloading = {}; // versionID -> isDownloading

  String _searchTerm = '';

  String? _error;

  // ===== GETTERS =====
  Map<String, VersionDto> get versions => _versions;

  VersionDto? getVersion(String firebaseId) {
    return _versions[firebaseId];
  }

  List<String> get filteredCloudVersionIds {
    if (_searchTerm.isEmpty) {
      return _versions.keys.toList();
    } else {
      final List<String> tempList = [];
      for (var entry in _versions.entries) {
        if (entry.value.title.toLowerCase().contains(_searchTerm) ||
            entry.value.author.toLowerCase().contains(_searchTerm) ||
            entry.value.tags.any(
              (tag) => tag.toLowerCase().contains(_searchTerm),
            )) {
          tempList.add(entry.key);
        }
      }
      return tempList;
    }
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool isDownloading(String versionID) => _isDownloading[versionID] ?? false;

  // ===== CREATE =====
  /// Persist the cache of an ID to the database
  Future<void> saveVersion(VersionDto version) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.publishPublicVersion(version);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error publishing public version: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void setVersion(String firebaseId, VersionDto version) {
    _versions[firebaseId] = version;
    notifyListeners();
  }
  // ===== READ =====
  /// Loads public versions from Firestore
  Future<void> loadVersions({
    bool forceReload = false,
    List<Cipher> localCiphers = const [],
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _versions.clear();
      final cloudVersions = await _repo.getPublicVersions(
        forceReload: forceReload,
      );

      for (var version in cloudVersions) {
        if (version.originalKey.isEmpty) {
          final recognizedKey = await _recognizer.recognizeKeyCloud(version);
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureVersionIsLoaded(String firebaseId) async {
    if (_versions.containsKey(firebaseId)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      VersionDto? version = await _repo.getUserVersionById(firebaseId);
      if (version != null) {
        if (version.originalKey.isEmpty) {
          final recognizedKey = await _recognizer.recognizeKeyCloud(version);
          version = version.copyWith(originalKey: recognizedKey);
        }
        _versions[firebaseId] = version;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring cloud version in cache: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
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
}
