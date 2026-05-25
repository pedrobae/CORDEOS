import 'package:flutter/foundation.dart';

/// Lightweight provider for managing EditSectionsScreen state
/// This allows tracking palette overlay and merge overlay without rebuilding expensive widget trees
class EditSectionsStateProvider extends ChangeNotifier {
  bool _paletteIsOpen = false;
  bool _mergeOverlayIsOpen = false;
  bool _annotationPaletteIsOpen = false;

  bool get paletteIsOpen => _paletteIsOpen;
  bool get mergeOverlayIsOpen => _mergeOverlayIsOpen;
  bool get annotationPaletteIsOpen => _annotationPaletteIsOpen;

  final List<int> _mergeSectionKeys = [];

  // ===== PALETTE METHODS =====
  void togglePalette() {
    _paletteIsOpen = !_paletteIsOpen;
    if (paletteIsOpen) {
      _mergeOverlayIsOpen = false;
      _annotationPaletteIsOpen = false;
    }
    notifyListeners();
  }

  void toggleAnnotationPalette() {
    _annotationPaletteIsOpen = !_annotationPaletteIsOpen;
    if (annotationPaletteIsOpen) {
      _mergeOverlayIsOpen = false;
      _paletteIsOpen = false;
    }
    notifyListeners();
  }

  // ===== MERGE OVERLAY METHODS =====
  List<int> get mergeSectionKeys => _mergeSectionKeys;

  void enableMergeOverlay() {
    _mergeOverlayIsOpen = true;
    _annotationPaletteIsOpen = false;
    _paletteIsOpen = false;
    notifyListeners();
  }

  void disableMergeOverlay() {
    _mergeOverlayIsOpen = false;
    _mergeSectionKeys.clear();
    notifyListeners();
  }

  void toggleMergeSection(int sectionKey) {
    if (_mergeSectionKeys.contains(sectionKey)) {
      _mergeSectionKeys.remove(sectionKey);
    } else {
      _mergeSectionKeys.add(sectionKey);
    }
    notifyListeners();
  }

  // ===== GENERAL METHODS =====
  void resetState() {
    _paletteIsOpen = false;
    _annotationPaletteIsOpen = false;
    _mergeOverlayIsOpen = false;
    _mergeSectionKeys.clear();
    notifyListeners();
  }
}
