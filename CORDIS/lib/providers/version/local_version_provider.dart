import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/repositories/local/version_repository.dart';
import 'package:flutter/foundation.dart';

class LocalVersionProvider extends ChangeNotifier {
  final LocalVersionRepository _repo = LocalVersionRepository();
  final Map<int, Version> _versions = {}; // Cached versions localID -> Version
  final List<int> _cachedDeletions = [];

  final Map<int, bool> _isLoadingVersion = {}; // versionId -> isLoading

  bool _isSaving = false;

  String? _error;

  bool _hasUnsavedChanges = false;

  // Getters
  Map<int, Version> get versions => _versions;

  bool get isSaving => _isSaving;

  String? get error => _error;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  int get localVersionCount {
    if (_versions[-1] != null) {
      return _versions.length - 1;
    }
    return _versions.length;
  }

  Version? getVersion(int versionID) {
    return _versions[versionID];
  }

  List<String> getSongStructure(int versionID) {
    return _versions[versionID]?.songStructure ?? [];
  }

  /// Checks if a version exists locally by its Firebase ID
  /// Returns the version if found, otherwise null
  Future<Version?> getVersionByFirebaseId(String firebaseId) async {
    for (var v in _versions.values) {
      if (v.firebaseID == firebaseId && v.id != null) {
        return v;
      }
    }
    // Not in cache, query repository
    final version = await _repo.getVersionWithFirebaseId(firebaseId);

    return version;
  }

  Future<String?> getFirebaseIdByLocalId(int localId) async {
    final id = _versions[localId]?.firebaseID;
    if (id != null) {
      return id;
    }
    // Not in cache, query repository
    final version = await _repo.getVersionWithId(localId);
    return version?.firebaseID;
  }

  // === Versions of a cipher ===
  List<int> getVersionsByCipherId(int cipherId) {
    return _versions.values
        .where((version) => version.cipherID == cipherId)
        .map((version) => version.id!)
        .toList();
  }

  int getVersionsOfCipherCount(int cipherId) {
    return _versions.values
        .where((version) => version.cipherID == cipherId)
        .length;
  }

  int? getIdOfOldestVersionOfCipher(int cipherId) {
    final versions = _versions.values
        .where((version) => version.cipherID == cipherId)
        .toList();
    versions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return versions.isNotEmpty ? versions.first.id : null;
  }

  // ===== CREATE =====
  /// Creates a new version from the local cache (-1) to an existing cipher
  /// If no cipherId is provided, the version will use the cached cipherID or throw an error
  Future<int?> createVersion({int? cipherID}) async {
    if (_isSaving) return null;

    _isSaving = true;
    _error = null;
    notifyListeners();

    int? versionId;
    try {
      if (!_versions.containsKey(-1)) {
        throw Exception('No version cached to create a new version from.');
      }
      // Create version with the correct cipher ID
      final versionWithCipherId = _versions[-1]!.copyWith(
        cipherID: cipherID ?? _versions[-1]!.cipherID,
      );

      if (versionWithCipherId.cipherID == -1) {
        throw Exception(
          'Cannot create version: no cipherId provided and cached version has no cipherId.',
        );
      }

      versionId = await _repo.insertVersion(versionWithCipherId);

      _versions[versionId] = versionWithCipherId.copyWith(id: versionId);

      debugPrint(
        'Created a new version with id $versionId, for cipher ${cipherID ?? versionWithCipherId.cipherID}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating cipher version: $e');
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
    return versionId;
  }

  /// Initialize cloud cache from domain object, with ID -1
  void setNewVersionInCache(Version version) {
    _versions[-1] = version;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  // ===== READ =====
  /// Load all versions of a cipher into cache, used for version selector and cipher expansion
  Future<void> loadVersionsOfCipher(int cipherId) async {
    try {
      _error = null;
      notifyListeners();

      final versionList = await _repo.getVersions(cipherId);
      for (final version in versionList) {
        _versions[version.id!] = version;
      }
      debugPrint('Loaded cipher $cipherId: VERSIONS - ${versionList.map((v) => v.id).toList()}');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading versions of cipher: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Load a version into cache by its local ID
  Future<void> loadVersion(int versionId) async {
    if (_isLoadingVersion[versionId] == true) return;

    _isLoadingVersion[versionId] = true;
    _error = null;
    notifyListeners();

    try {
      final version = await _repo.getVersionWithId(versionId);
      if (version == null) {
        throw Exception('Version with id $versionId not found locally');
      }

      _versions[versionId] = version;
      debugPrint(
        'Loaded the version: ${_versions[versionId]?.versionName} into cache',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading version by id: $e');
    } finally {
      _isLoadingVersion[versionId] = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Fetches a version directly from SQLite
  Future<Version?> fetchVersion(int versionID) async {
    if (_isLoadingVersion[versionID] == true) return null;

    Version? version;

    try {
      _isLoadingVersion[versionID] = true;
      _error = null;
      notifyListeners();

      version = await _repo.getVersionWithId(versionID);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingVersion[versionID] = false;
      notifyListeners();
    }

    return version;
  }

  // ===== UPSERT =====
  /// Upsert a version into local db (used when download a version from the cloud)
  Future<int> upsertVersion(Version version) async {
    int versionId = -1;
    if (_isSaving) return versionId;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Check if version exists by its firebaseId
      final existingVersion = await _repo.getVersionWithFirebaseId(
        version.firebaseID!,
      );

      if (existingVersion != null) {
        // Update existing version
        versionId = existingVersion.id!;
        await _repo.updateVersion(version.copyWith(id: existingVersion.id));
        debugPrint('Updated existing version with id: ${existingVersion.id}');
      } else {
        // Insert new version
        versionId = await _repo.insertVersion(version);
        debugPrint('Inserted new version with id: $versionId');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error upserting cipher version: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return versionId;
  }

  // ===== UPDATE - update cipher version =====
  /// Updates a version in the local database (nothing to do with cache)
  Future<void> updateVersion(Version version) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.updateVersion(version);
      loadVersion(version.id!);

      debugPrint('Updated version with id: ${version.id}');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating cipher version: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Cache changes to the version data (Version Name / Transposed Key)
  void cacheUpdates(
    int versionId, {
    String? versionName,
    String? transposedKey,
    List<String>? songStructure,
    Duration? duration,
    int? bpm,
  }) {
    _versions[versionId] = _versions[versionId]!.copyWith(
      versionName: versionName,
      transposedKey: transposedKey,
      songStructure: songStructure,
      duration: duration,
      bpm: bpm,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  // Reorder and cache a new structure
  void reorderSongStructure(int versionId, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final newStruct = List<String>.from(_versions[versionId]!.songStructure);
    final item = newStruct.removeAt(oldIndex);
    newStruct.insert(newIndex, item);

    _versions[versionId] = _versions[versionId]!.copyWith(
      songStructure: newStruct,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
    return;
  }

  /// Cache the deletion of a version by its ID,
  /// The actual deletion will be done when saving changes
  void cacheDeletion(int versionId) {
    _cachedDeletions.add(versionId);
    _versions.remove(versionId);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// ===== DELETE - Version =====
  Future<int?> deleteVersion(int versionId) async {
    int? cipherID;
    if (_isSaving) return cipherID;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      cipherID = await _repo.deleteVersion(versionId);
      debugPrint('Deleted version with id: $versionId');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting cipher version: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return cipherID;
  }

  Future<void> persistCachedDeletions() async {
    for (final versionId in _cachedDeletions) {
      await deleteVersion(versionId);
    }
    _cachedDeletions.clear();
  }

  // ===== SAVE =====
  /// Persist the cache of an ID to the database
  Future<void> saveVersion({required int versionID}) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.updateVersion(_versions[versionID]!);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating cipher version: $e');
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// ===== SONG STRUCTURE =====
  /// ===== CREATE =====
  // Add a new section
  void addSectionToStruct(int versionId, String contentCode) {
    final newStruct = List<String>.from(_versions[versionId]!.songStructure);
    newStruct.add(contentCode);

    _versions[versionId] = _versions[versionId]!.copyWith(
      songStructure: newStruct,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  // ===== UPDATE =====
  /// Update a section code in the song structure
  void updateSectionCodeInStruct(
    int versionId, {
    required String oldCode,
    required String newCode,
  }) {
    // Iterate through the song structure and update the section code
    final newStruct = List<String>.from(_versions[versionId]!.songStructure);
    for (int i = 0; i < newStruct.length; i++) {
      if (newStruct[i] == oldCode) {
        newStruct[i] = newCode;
      }
    }

    _versions[versionId] = _versions[versionId]!.copyWith(
      songStructure: newStruct,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// ===== DELETE =====
  void removeSectionsByCode(int versionId, String contentCode) {
    final newStruct = List<String>.from(_versions[versionId]!.songStructure);
    newStruct.removeWhere((code) => code == contentCode);
    _versions[versionId] = _versions[versionId]!.copyWith(
      songStructure: newStruct,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void removeSection(int versionID, int index) {
    final newStruct = List<String>.from(_versions[versionID]!.songStructure);
    newStruct.removeAt(index);
    _versions[versionID] = _versions[versionID]!.copyWith(
      songStructure: newStruct,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void clearCache() {
    _versions.clear();
    _isLoadingVersion.clear();
    _isSaving = false;
    _error = null;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
  }
}
