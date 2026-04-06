import 'package:flutter/material.dart';
import 'package:cordeos/services/settings_service.dart';

class LayoutSetProvider extends ChangeNotifier {
  double fontSize = 16;
  String fontFamily = 'OpenSans';
  bool showSectionHeaders = true;
  Axis scrollDirection = Axis.vertical;

  Axis get wrapDirection =>
      scrollDirection == Axis.vertical ? Axis.horizontal : Axis.vertical;
  double cardWidthMult = 0.9;

  double lineSpacing = 3;
  double lineBreakSpacing = 0;
  double chordLyricSpacing = 0;
  double minChordSpacing = 4;
  double letterSpacing = 0;

  bool _showChords = true;
  bool _showLyrics = true;
  bool _showAnnotations = true;
  bool _showTransitions = true;
  bool _showRepeatSections = true;

  bool get showChords => _showChords;
  bool get showLyrics => _showLyrics;
  bool get showAnnotations => _showAnnotations;
  bool get showTransitions => _showTransitions;
  bool get showRepeatSections => _showRepeatSections;

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    fontSize = SettingsService.getFontSize();
    fontFamily = SettingsService.getFontFamily();
    scrollDirection = SettingsService.getScrollDirection();
    _showChords = SettingsService.getShowChords();
    _showLyrics = SettingsService.getShowLyrics();
    _showAnnotations = SettingsService.getShowNotes();
    _showRepeatSections = SettingsService.getShowRepeatSections();
    _showTransitions = SettingsService.getShowTransitions();
    showSectionHeaders = SettingsService.getShowSectionHeaders();
    cardWidthMult = SettingsService.getCardWidthMult();
    lineSpacing = SettingsService.getLineSpacing();
    lineBreakSpacing = SettingsService.getLineBreakSpacing();
    chordLyricSpacing = SettingsService.getChordLyricSpacing();
    minChordSpacing = SettingsService.getMinChordSpacing();
    letterSpacing = SettingsService.getLetterSpacing();
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

  void setLineSpacing(double value) {
    lineSpacing = value;
    SettingsService.setLineSpacing(value);
    notifyListeners();
  }

  void setLineBreakSpacing(double value) {
    lineBreakSpacing = value;
    SettingsService.setLineBreakSpacing(value);
    notifyListeners();
  }

  void setChordLyricSpacing(double value) {
    chordLyricSpacing = value;
    SettingsService.setChordLyricSpacing(value);
    notifyListeners();
  }

  void setMinChordSpacing(double value) {
    minChordSpacing = value;
    SettingsService.setMinChordSpacing(value);
    notifyListeners();
  }

  void setLetterSpacing(double value) {
    letterSpacing = value;
    SettingsService.setLetterSpacing(value);
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

  void toggleAnnotations() {
    _showAnnotations = !_showAnnotations;
    SettingsService.setShowNotes(_showAnnotations);
    notifyListeners();
  }

  void toggleTransitions() {
    _showTransitions = !_showTransitions;
    SettingsService.setShowTransitions(_showTransitions);
    notifyListeners();
  }

  void toggleRepeatSections() {
    _showRepeatSections = !_showRepeatSections;
    SettingsService.setShowRepeatSections(_showRepeatSections);
    notifyListeners();
  }

  TextStyle get chordTextStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    fontWeight: FontWeight.bold,
    height: 1,
    letterSpacing: 0,
  );

  TextStyle get lyricTextStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    height: 1,
    letterSpacing: 0,
  );
}
