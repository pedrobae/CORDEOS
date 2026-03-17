import 'package:flutter/material.dart';
import 'package:cordis/services/settings_service.dart';

enum ContentFilter { chords, lyrics }

enum LayoutFilter { annotations, transitions }

class LayoutSetProvider extends ChangeNotifier {
  double fontSize = 16;
  String fontFamily = 'OpenSans';
  bool showSectionHeaders = true;
  Axis scrollDirection = Axis.vertical;

  Axis get wrapDirection =>
      scrollDirection == Axis.vertical ? Axis.horizontal : Axis.vertical;
  double cardWidthMult = 0.9;

  bool _showChords = true;
  bool _showLyrics = true;
  bool _showAnnotations = true;
  bool _showTransitions = true;

  Map<ContentFilter, bool> get contentFilters => {
    ContentFilter.chords: _showChords,
    ContentFilter.lyrics: _showLyrics,
  };

  Map<LayoutFilter, bool> get layoutFilters => {
    LayoutFilter.annotations: _showAnnotations,
    LayoutFilter.transitions: _showTransitions,
  };

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    fontSize = SettingsService.getFontSize();
    fontFamily = SettingsService.getFontFamily();
    scrollDirection = SettingsService.getScrollDirection();
    _showChords = SettingsService.getShowChords();
    _showLyrics = SettingsService.getShowLyrics();
    _showAnnotations = SettingsService.getShowNotes();
    _showTransitions = SettingsService.getShowTransitions();
    showSectionHeaders = SettingsService.getShowSectionHeaders();
    cardWidthMult = SettingsService.getCardWidthMult();
    notifyListeners();
  }

  // Add setters that call notifyListeners() and persist to storage
  void setFontSize(double value) {
    fontSize = value;
    SettingsService.setFontSize(value);
    notifyListeners();
  }

  void setFontFamily(String family) {
    fontFamily = family;
    SettingsService.setFontFamily(family);
    notifyListeners();
  }

  void toggleAxisDirection() {
    scrollDirection = scrollDirection == Axis.vertical
        ? Axis.horizontal
        : Axis.vertical;
    SettingsService.setScrollDirection(scrollDirection);
    notifyListeners();
  }

  void setCardWidthMult(double value) {
    cardWidthMult = value;
    SettingsService.setCardWidthMult(value);
    notifyListeners();
  }

  void toggleSectionHeaders() {
    showSectionHeaders = !showSectionHeaders;
    SettingsService.setShowSectionHeaders(showSectionHeaders);
    notifyListeners();
  }

  void toggleChords() {
    _showChords = !_showChords;
    SettingsService.setShowChords(_showChords);
    notifyListeners();
  }

  void toggleLyrics() {
    _showLyrics = !_showLyrics;
    SettingsService.setShowLyrics(_showLyrics);
    notifyListeners();
  }

  void toggleNotes() {
    _showAnnotations = !_showAnnotations;
    SettingsService.setShowNotes(_showAnnotations);
    notifyListeners();
  }

  void toggleTransitions() {
    _showTransitions = !_showTransitions;
    SettingsService.setShowTransitions(_showTransitions);
    notifyListeners();
  }

  TextStyle chordTextStyle(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    color: color,
    fontWeight: FontWeight.bold,
    height: 2,
    letterSpacing: 0,
  );

  TextStyle get lyricTextStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    height: 2,
    letterSpacing: 0,
  );
}
