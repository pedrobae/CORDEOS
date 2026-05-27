import 'package:flutter/material.dart';
import 'package:cordeos/services/settings_service.dart';

class LayoutSetProvider extends ChangeNotifier {
  double fontSize = 16;
  String fontFamily = 'OpenSans';
  bool showSectionHeaders = true;
  Axis scrollDirection = Axis.vertical;

  Axis get wrapDirection =>
      scrollDirection == Axis.vertical ? Axis.horizontal : Axis.vertical;
  double cardWidthMult = 1.0;

  double heightSpacingMult = 0;

  double get heightSpacing => heightSpacingMult * fontSize;

  final double minChordSpacing = 4;
  final double letterSpacing = 0;

  bool _showChordBass = true;
  bool _showAddedNotes = true;
  bool get showChordBass => _showChordBass;
  bool get showAddedNotes => _showAddedNotes;

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
    _showChordBass = SettingsService.getShowChordBass();
    _showAddedNotes = SettingsService.getShowAddedNotes();
    _showChords = SettingsService.getShowChords();
    _showLyrics = SettingsService.getShowLyrics();
    _showAnnotations = SettingsService.getShowNotes();
    _showRepeatSections = SettingsService.getShowRepeatSections();
    _showTransitions = SettingsService.getShowTransitions();
    showSectionHeaders = SettingsService.getShowSectionHeaders();
    cardWidthMult = SettingsService.getCardWidthMult();
    heightSpacingMult = SettingsService.getHeightSpacing();
    // minChordSpacing = SettingsService.getMinChordSpacing();
    // letterSpacing = SettingsService.getLetterSpacing();
    notifyListeners();
  }

  // Add setters that call notifyListeners() and persist to storage
  Future<void> setFontSize(double value) async {
    fontSize = value;
    await SettingsService.setFontSize(value);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    fontFamily = family;
    await SettingsService.setFontFamily(family);
    notifyListeners();
  }

  Future<void> toggleAxisDirection() async {
    scrollDirection = scrollDirection == Axis.vertical
        ? Axis.horizontal
        : Axis.vertical;
    await SettingsService.setScrollDirection(scrollDirection);
    notifyListeners();
  }

  Future<void> setCardWidthMult(double value) async {
    cardWidthMult = value;
    await SettingsService.setCardWidthMult(value);
    notifyListeners();
  }

  Future<void> setHeightSpacingMult(double value) async {
    heightSpacingMult = value;
    await SettingsService.setHeightSpacingMult(value);
    notifyListeners();
  }

  Future<void> toggleSectionHeaders() async {
    showSectionHeaders = !showSectionHeaders;
    await SettingsService.setShowSectionHeaders(showSectionHeaders);
    notifyListeners();
  }

  Future<void> toggleChordBass() async {
    _showChordBass = !_showChordBass;
    await SettingsService.setShowChordBass(_showChordBass);
    notifyListeners();
  }

  Future<void> toggleAddedNotes() async {
    _showAddedNotes = !_showAddedNotes;
    await SettingsService.setShowAddedNotes(_showAddedNotes);
    notifyListeners();
  }

  Future<void> toggleChords() async {
    _showChords = !_showChords;
    await SettingsService.setShowChords(_showChords);
    notifyListeners();
  }

  Future<void> toggleLyrics() async {
    _showLyrics = !_showLyrics;
    await SettingsService.setShowLyrics(_showLyrics);
    notifyListeners();
  }

  Future<void> toggleAnnotations() async {
    _showAnnotations = !_showAnnotations;
    await SettingsService.setShowNotes(_showAnnotations);
    notifyListeners();
  }

  Future<void> toggleTransitions() async {
    _showTransitions = !_showTransitions;
    await SettingsService.setShowTransitions(_showTransitions);
    notifyListeners();
  }

  Future<void> toggleRepeatSections() async {
    _showRepeatSections = !_showRepeatSections;
    await SettingsService.setShowRepeatSections(_showRepeatSections);
    notifyListeners();
  }

  TextStyle get chordStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    fontWeight: FontWeight.bold,
    height: 1,
    letterSpacing: 0,
  );

  TextStyle get lyricStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize.toDouble(),
    height: 1,
    letterSpacing: 0,
  );

  TextStyle get annotationStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontStyle: FontStyle.italic,
    height: 1,
    letterSpacing: 0,
  );
}
