import 'package:cordis/repositories/local/section_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cordis/models/domain/cipher/section.dart';

class SectionProvider extends ChangeNotifier {
  final _repo = SectionRepository();

  SectionProvider();

  Map<dynamic, Map<String, Section>> _sections =
      {}; // versionId -> (sectionCode -> Section) -1 versionId for new/importing versions
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String? get error => _error;

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
      versionId: versionKey is String ? -1 : versionKey,
      contentCode: code,
      contentColor: color,
      contentType: sectionType,
      contentText: '',
    );

    _sections[newSection.versionId] ??= {};
    _sections[newSection.versionId]![newSection.contentCode] = newSection;
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

  void cacheSectionCopy(dynamic versionId) {
    final sections = _sections[versionId];
    if (sections == null) return;

    _sections[-1] ??= {};

    for (final code in sections.keys) {
      final originalSection = sections[code]!;
      final newSection = originalSection.copyWith(versionId: -1);
      _sections[-1]![newSection.contentCode] = newSection;
    }
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  ///Create sections for a new version from -1 cache
  Future<void> createSections(int newVersionId) async {
    final sections = _sections[-1];
    for (final code in sections!.keys) {
      await _repo.insertSection(
        sections[code]!.copyWith(versionId: newVersionId),
      );
    }
    _sections.remove(-1);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ====== READ =====
  /// Load sections for a given version from the database
  Future<void> loadSectionsOfVersion(int versionId) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _sections[versionId] = await _repo.getSections(versionId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('⚠️ Failed to load sections: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ===== UPDATE =====
  // Modify a section (content_text)
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

    final section = _sections[versionID]![contentCode];
    if (section == null) {
      // Create a new section if it doesn't exist
      final newSection = Section(
        versionId: versionID is String ? -1 : versionID,
        contentCode: newCode,
        contentType: newContentType ?? 'default',
        contentText: newContentText ?? '',
        contentColor: newColor ?? Colors.grey,
      );

      _sections[newSection.versionId] ??= {};
      _sections[newSection.versionId]![newSection.contentCode] = newSection;
    } else {
      // Update existing section
      section.contentCode = newCode;
      section.contentType = newContentType ?? section.contentType;
      section.contentText = newContentText ?? section.contentText;
      section.contentColor = newColor ?? section.contentColor;
    }
    _hasUnsavedChanges = true;
    notifyListeners();
    return newCode;
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
  void cacheDeleteSection(dynamic versionKey, String sectionCode) {
    _sections[versionKey]!.remove(sectionCode);
    _hasUnsavedChanges = true;
    notifyListeners();
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
        await _repo.upsertSection(entry.value.copyWith(versionId: versionID));
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
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
  }
}
