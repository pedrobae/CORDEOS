import 'package:cordeos/repositories/local/section_repository.dart';
import 'package:flutter/material.dart';

import 'package:cordeos/models/domain/cipher/section.dart';

class SectionProvider extends ChangeNotifier {
  final _repo = SectionRepository();

  SectionProvider();

  Map<dynamic, Map<int, Section>> _sections =
      {}; // versionKey -> (sectionKey -> Section) -1 versionId for new/importing versions
  Map<dynamic, bool> _isLoadingVersion = {}; // versionId -> isLoading
  bool _hasUnsavedChanges = false;
  //
  final List<List<int>> _cachedDeletions = [];

  String? _error;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String? get error => _error;

  /// Number of versions that currently have their sections loaded in cache.
  /// Changes whenever a version's sections finish loading — use in Selectors
  /// that need to rebuild when any version's section data becomes available.
  int get loadedVersionsCount => _sections.length;

  Map<int, Section> getSections(dynamic versionKey) {
    if (versionKey != null && _sections.containsKey(versionKey)) {
      return _sections[versionKey]!;
    }
    return {};
  }

  Section? getSection({required dynamic versionKey, dynamic sectionKey}) {
    if (versionKey == null || sectionKey == null) return null;
    switch (versionKey.runtimeType) {
      case const (String):
        return _sections[versionKey]?[sectionKey];
      case const (int):
        return _sections[versionKey]?[sectionKey];
      default:
        return null;
    }
  }

  /// ===== CREATE =====
  // Add a new section, returns the new section code (with suffix if there was a conflict)
  int cacheAddSection(dynamic versionKey, Color color, String sectionType) {
    final key = _getAvailableKey(versionKey);
    final newSection = Section(
      key: key,
      versionID: versionKey is String
          ? -1
          : versionKey, // if versionKey is String, it's a new/importing version, so use -1 as placeholder
      contentColor: color,
      contentType: sectionType,
      contentText: '',
    );

    _sections[newSection.versionID] ??= {};
    _sections[newSection.versionID]![key] = newSection;
    _hasUnsavedChanges = true;
    notifyListeners();
    return key;
  }

  // Set new sections in cache (used when importing or on cloud load)
  void setNewSectionsInCache(dynamic versionKey, Map<int, Section> sections) {
    _sections[versionKey] = sections;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void cacheCopyOfVersion(dynamic versionId, int copyId) {
    final sections = _sections[versionId];
    if (sections == null) return;

    _sections[copyId] ??= {};

    for (final code in sections.keys) {
      final originalSection = sections[code]!;
      final newSection = originalSection.copyWith(versionID: copyId);
      _sections[copyId]![code] = newSection;
    }
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  dynamic cacheCopyOfSection({
    required dynamic versionId,
    required dynamic sectionKey,
  }) {
    final section = _sections[versionId]?[sectionKey];
    if (section == null) return null;

    final newKey = _getAvailableKey(versionId);
    final newSection = section.copyWith(id: newKey);
    _sections[versionId]![newKey] = newSection;

    _hasUnsavedChanges = true;
    notifyListeners();
    return newKey;
  }

  ///Create sections for a new version from -1 cache
  Future<void> createSections(int newVersionId, {int originKey = -1}) async {
    final sections = _sections[originKey];
    for (final code in sections!.keys) {
      await _repo.insertSection(
        sections[code]!.copyWith(versionID: newVersionId),
      );
    }
    _sections.remove(originKey);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ====== READ =====
  /// Ensures all sections of given structure and version is loaded
  Future<void> ensureAreLoaded(
    int versionID,
    List<int> songStruct,
  ) async {
    if (_sections[versionID] != null &&
        songStruct.every((key) => _sections[versionID]!.containsKey(key)))
      return;
    if (_isLoadingVersion[versionID] == true) return;

    _isLoadingVersion[versionID] = true;
    notifyListeners();

    try {
      _sections[versionID] = await _repo.getSections(versionID);
      debugPrint(
        "SECTION - Loaded version $versionID's SECTIONS - ${_sections[versionID]!.length} loaded",
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('SECTION PROVIDER - Failed to load sections: $e');
    } finally {
      _isLoadingVersion[versionID] = false;
      notifyListeners();
    }
  }

  /// Load sections for a given version from the database
  Future<void> loadSectionsOfVersion(int versionID) async {
    if (_isLoadingVersion[versionID] == true) return;

    _isLoadingVersion[versionID] = true;
    notifyListeners();

    try {
      _sections[versionID] = await _repo.getSections(versionID);
      debugPrint(
        "SECTION - Loaded version $versionID's SECTIONS - ${_sections[versionID]!.length} loaded",
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('SECTION PROVIDER - Failed to load sections: $e');
    } finally {
      _isLoadingVersion[versionID] = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Load a single section into cache (used when discarding changes on edit)
  /// Returns the loaded section, or clears the section from cache if loading fails
  Future<void> loadSection(dynamic versionId, dynamic sectionKey) async {
    try {
      final section = await _repo.getSection(versionId, sectionKey);
      if (section != null) {
        _sections[versionId] ??= {};
        _sections[versionId]![sectionKey] = section;
        notifyListeners();
      } else {
        throw Exception('Section not found in database.');
      }
    } catch (e) {
      _error = e.toString();
      _sections[versionId]?.remove(sectionKey);
      debugPrint('SECTION PROVIDER - Failed to load section: $e');
      notifyListeners();
    }
  }

  /// ===== UPDATE =====
  void cacheUpdate(
    dynamic versionID,
    dynamic sectionKey, {
    String? newContentType,
    String? newContentText,
    Color? newColor,
  }) {
    final section = _sections[versionID]?[sectionKey];
    if (section == null) return;

    section.contentType = newContentType ?? section.contentType;
    section.contentColor = newColor ?? section.contentColor;
    section.contentText = newContentText ?? section.contentText;

    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// ===== DELETE =====
  // Remove all sections by its code
  void cacheDeletion(int versionKey, int sectionKey) {
    _sections[versionKey]!.remove(sectionKey);
    _cachedDeletions.add([versionKey, sectionKey]);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> deleteSectionsOfVersion(int versionID) async {
    await _repo.deleteSections(versionID);
  }

  // ===== SAVE =====
  /// Persist the data of the given version key to the database
  Future<void> saveSections({dynamic versionID}) async {
    try {
      if (versionID == null) {
        throw Exception('No version key provided.');
      }

      if (versionID is String) {
        throw Exception('Cannot save sections for non-local version.');
      }

      for (final entry in _sections[versionID]!.entries) {
        await _repo.upsertSection(entry.value.copyWith(versionID: versionID));
      }
      for (final deletion in _cachedDeletions) {
        await _repo.deleteSection(deletion[0], deletion[1]);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('SECTION PROVIDER - error saving sections: $e');
    } finally {
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  Future<void> saveSection({
    required dynamic versionKey,
    required int sectionKey,
  }) async {
    notifyListeners();

    try {
      if (versionKey == null) {
        throw Exception('No version key provided.');
      }
      if (versionKey is String) {
        throw Exception('Cannot save section for non-local version.');
      }

      final section = _sections[versionKey]?[sectionKey];
      if (section == null) {
        throw Exception('Section not found in cache.');
      }

      await _repo.upsertSection(section);
    } catch (e) {
      _error = e.toString();
      debugPrint('SECTION PROVIDER - error saving section: $e');
    } finally {
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Clear all sections from cache
  void clearCache() {
    _sections = {};
    _isLoadingVersion = {};
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
  }

  int _getAvailableKey(dynamic versionKey) {
    final existingKeys = _sections[versionKey]!.keys;
    int key = 1;
    while (existingKeys.contains(key)) {
      key++;
    }
    return key;
  }
}
