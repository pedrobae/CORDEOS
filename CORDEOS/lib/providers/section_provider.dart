import 'package:cordeos/repositories/local/section_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cordeos/models/domain/cipher/section.dart';

class SectionProvider extends ChangeNotifier {
  final _repo = SectionRepository();

  SectionProvider();

  Map<dynamic, Map<String, Section>> _sections =
      {}; // versionId -> (sectionCode -> Section) -1 versionId for new/importing versions
  Map<dynamic, bool> _isLoadingVersion = {}; // versionId -> isLoading
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  final List<MapEntry<int, String>> _cachedDeletions = [];

  String? _error;

  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String? get error => _error;

  /// Number of versions that currently have their sections loaded in cache.
  /// Changes whenever a version's sections finish loading — use in Selectors
  /// that need to rebuild when any version's section data becomes available.
  int get loadedVersionsCount => _sections.length;

  Map<String, Section> getSections(dynamic versionKey) {
    if (versionKey != null && _sections.containsKey(versionKey)) {
      return _sections[versionKey]!;
    }
    return {};
  }

  Section? getSection(dynamic versionKey, String contentCode) {
    switch (versionKey.runtimeType) {
      case const (String):
        return _sections[versionKey]?[contentCode];
      case const (int):
        return _sections[versionKey]?[contentCode];
      default:
        return _sections[-1]?[contentCode]; // For new/importing versions
    }
  }

  /// ===== CREATE =====
  // Add a new section, returns the new section code (with suffix if there was a conflict)
  String cacheAddSection(
    dynamic versionKey,
    String contentCode,
    Color color,
    String sectionType,
  ) {
    final code = _assignNumbering(versionKey, '', contentCode);
    final newSection = Section(
      versionID: versionKey is String ? -1 : versionKey,
      contentCode: code,
      contentColor: color,
      contentType: sectionType,
      contentText: '',
    );

    _sections[newSection.versionID] ??= {};
    _sections[newSection.versionID]![newSection.contentCode] = newSection;
    _hasUnsavedChanges = true;
    notifyListeners();
    return newSection.contentCode;
  }

  // Set new sections in cache (used when importing or on cloud load)
  void setNewSectionsInCache(
    dynamic versionKey,
    Map<String, Section> sections,
  ) {
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

  String? cacheCopyOfSection({
    required dynamic versionId,
    required String sectionCode,
  }) {
    final section = _sections[versionId]?[sectionCode];
    if (section == null) return null;

    final newCode = _assignNumbering(versionId, '', section.contentCode);

    final newSection = section.copyWith(contentCode: newCode);
    _sections[versionId]![newSection.contentCode] = newSection;

    _hasUnsavedChanges = true;
    notifyListeners();
    return newCode;
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
  /// Load sections for a given version from the database
  Future<void> loadSectionsOfVersion(int versionId) async {
    if (_isLoadingVersion[versionId] == true) return;

    _isLoadingVersion[versionId] = true;
    notifyListeners();

    try {
      _sections[versionId] = await _repo.getSections(versionId);
      debugPrint("SECTION - Loaded version $versionId's SECTIONS - ${_sections[versionId]!.length} loaded");
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('⚠️ Failed to load sections: $e');
      }
    } finally {
      _isLoadingVersion[versionId] = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// ===== UPDATE =====
  String cacheUpdate(
    dynamic versionID,
    String contentCode, {
    String? newContentCode,
    String? newContentType,
    String? newContentText,
    Color? newColor,
  }) {
    String newCode = contentCode;
    if (newContentCode != null) {
      newCode = _assignNumbering(versionID, contentCode, newContentCode);
    }

    final section = _sections[versionID]![contentCode]!;
    section.contentCode = newCode;
    section.contentType = newContentType ?? section.contentType;
    section.contentColor = newColor ?? section.contentColor;
    section.contentText = newContentText ?? section.contentText;

    _hasUnsavedChanges = true;
    notifyListeners();
    return newCode;
  }

  void cacheContent({
    required String sectionCode,
    required int versionID,
    required String content,
  }) {
    _sections[versionID]![sectionCode]!.contentText = content;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void renameSectionKey(
    dynamic versionID, {
    required String oldCode,
    required String newCode,
  }) {
    final section = _sections[versionID]![oldCode];
    if (section == null) return;

    // Remove the old entry and add a new one with the updated code
    _sections[versionID]!.remove(oldCode);
    _sections[versionID]![newCode] = section;

    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// ===== DELETE =====
  // Remove all sections by its code
  void cacheDeletion(dynamic versionKey, String sectionCode) {
    _sections[versionKey]!.remove(sectionCode);
    _cachedDeletions.add(MapEntry(versionKey as int, sectionCode));
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> deleteSectionsOfVersion(int versionID) async {
    await _repo.deleteSections(versionID);
  }

  // ===== SAVE =====
  /// Persist the data of the given version key to the database
  Future<void> saveSections({dynamic versionID}) async {
    if (_isSaving) return;

    _isSaving = true;
    notifyListeners();

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
        await _repo.deleteSection(deletion.key, deletion.value);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('⚠️ Failed to save sections: $e');
      }
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  String _assignNumbering(
    dynamic versionID,
    String originalCode,
    String newBaseCode,
  ) {
    // CHECK IF ALREADY EXISTS
    final matchingCodes = <String>[];
    for (String code in _sections[versionID]?.keys ?? []) {
      if (code == originalCode) {
        continue; // Skip the original code when renaming
      }
      // Strip numbering suffixes for comparison
      final strippedCode = code.toString().replaceAll(RegExp(r'\d+$'), '');
      if (strippedCode == newBaseCode) {
        matchingCodes.add(code);
      }
    }
    // If there are more than 1 matching codes, it means there is a possible conflict
    if (matchingCodes.isNotEmpty && originalCode != newBaseCode) {
      // // CHECK IF THERE IS A CODE WITH NO NUMBERING
      // if (matchingCodes.contains(newBaseCode)) {
      //   // And add 1 suffixes to all other matching codes
      //   // Return the following available number suffix for the new section

      //   // Sort matching codes by their numerical suffix to avoid conflicts when renaming
      //   matchingCodes.sort((a, b) {
      //     final aSuffix =
      //         int.tryParse(a.toString().substring(newBaseCode.length)) ?? 0;
      //     final bSuffix =
      //         int.tryParse(b.toString().substring(newBaseCode.length)) ?? 0;
      //     return -aSuffix.compareTo(-bSuffix);
      //   });

      //   for (String code in matchingCodes) {
      //     final existingSuffix =
      //         int.tryParse(code.toString().substring(newBaseCode.length)) ?? 0;

      //     renameSectionKey(
      //       versionID,
      //       oldCode: code,
      //       newCode: '$newBaseCode${existingSuffix + 1}',
      //     );
      //   }
      // }
      debugPrint(
        'Section with code $newBaseCode already exists in version $versionID.',
      );
      _hasUnsavedChanges = true;
      return '$newBaseCode${matchingCodes.length + 1}'; // New section gets the next available suffix
    }
    return newBaseCode; // No conflicts, return just the base code
  }

  /// Clear all sections from cache
  void clearCache() {
    _sections = {};
    _isLoadingVersion = {};
    _isSaving = false;
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
  }
}
