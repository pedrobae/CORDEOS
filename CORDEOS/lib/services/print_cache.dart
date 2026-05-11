import 'package:shared_preferences/shared_preferences.dart';

class PrintCacheService {
  // Style Settings Keys
  static const String _keyFontSize = 'print_font_size';
  static const String _keyFontFamily = 'print_font_family';

  // Layout Settings Keys
  static const String _keyHeightSpacingMult = 'print_height_spacing_mult';
  static const String _keyLetterSpacing = 'print_letter_spacing';

  // Filter Settings Keys
  static const String _keyShowHeader = 'print_show_header';
  static const String _keyShowSongMap = 'print_show_map';
  static const String _keyShowBpm = 'print_show_bpm';
  static const String _keyShowDuration = 'print_show_duration';

  static const String _keyShowAnnotations = 'print_show_annotations';
  static const String _keyShowRepeatSections = 'print_show_repeat_sections';

  static const String _keyShowLabel = 'print_show_labels';

  static const String _keyShowChords = 'print_show_chords';
  static const String _keyShowLyrics = 'print_show_lyrics';

  // Page Layout Settings Keys
  static const String _keyMargin = 'print_margin';
  static const String _keyColumnCount = 'print_column_count';
  static const String _keyInternalGap = 'print_internal_gap';

  static SharedPreferences? _prefs;

  /// Initialize the service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get _preferences {
    assert(_prefs != null, 'SettingsService must be initialized first');
    return _prefs!;
  }

  // =========== LAYOUT SETTINGS =============

  static Future<void> setSize(double size) async {
    await _preferences.setDouble(_keyFontSize, size);
  }

  static double getSize() {
    return _preferences.getDouble(_keyFontSize) ?? 12.0;
  }

  static Future<void> setFontFamily(String family) async {
    await _preferences.setString(_keyFontFamily, family);
  }

  static String getFontFamily() {
    return _preferences.getString(_keyFontFamily) ?? 'OpenSans';
  }

  static Future<void> setHeightSpacingMult(double spacing) async {
    await _preferences.setDouble(_keyHeightSpacingMult, spacing);
  }

  static double getHeightSpacingMult() {
    return _preferences.getDouble(_keyHeightSpacingMult) ?? 0.1;
  }

  static Future<void> setLetterSpacing(double spacing) async {
    await _preferences.setDouble(_keyLetterSpacing, spacing);
  }

  static double getLetterSpacing() {
    return _preferences.getDouble(_keyLetterSpacing) ?? 0.0;
  }

  // =========== FILTER SETTINGS =============

  static Future<void> setShowHeader(bool show) async {
    await _preferences.setBool(_keyShowHeader, show);
  }

  static bool getShowHeader() {
    return _preferences.getBool(_keyShowHeader) ?? true;
  }

  static Future<void> setShowSongMap(bool show) async {
    await _preferences.setBool(_keyShowSongMap, show);
  }

  static bool getShowSongMap() {
    return _preferences.getBool(_keyShowSongMap) ?? true;
  }

  static Future<void> setShowBpm(bool show) async {
    await _preferences.setBool(_keyShowBpm, show);
  }

  static bool getShowBpm() {
    return _preferences.getBool(_keyShowBpm) ?? true;
  }

  static Future<void> setShowDuration(bool show) async {
    await _preferences.setBool(_keyShowDuration, show);
  }

  static bool getShowDuration() {
    return _preferences.getBool(_keyShowDuration) ?? true;
  }

  static Future<void> setShowChords(bool show) async {
    await _preferences.setBool(_keyShowChords, show);
  }

  static bool getShowChords() {
    return _preferences.getBool(_keyShowChords) ?? true;
  }

  static Future<void> setShowLyrics(bool show) async {
    await _preferences.setBool(_keyShowLyrics, show);
  }

  static bool getShowLyrics() {
    return _preferences.getBool(_keyShowLyrics) ?? true;
  }

  static Future<void> setShowAnnotations(bool show) async {
    await _preferences.setBool(_keyShowAnnotations, show);
  }

  static bool getShowAnnotations() {
    return _preferences.getBool(_keyShowAnnotations) ?? true;
  }

  static Future<void> setShowRepeatSections(bool show) async {
    await _preferences.setBool(_keyShowRepeatSections, show);
  }

  static bool getShowRepeatSections() {
    return _preferences.getBool(_keyShowRepeatSections) ?? true;
  }

  static Future<void> setShowLabel(bool show) async {
    await _preferences.setBool(_keyShowLabel, show);
  }

  static bool getShowLabel() {
    return _preferences.getBool(_keyShowLabel) ?? true;
  }

  // =========== PAGE LAYOUT SETTINGS =============

  static Future<void> setMargin(double margin) async {
    await _preferences.setDouble(_keyMargin, margin);
  }

  static double getMargin() {
    return _preferences.getDouble(_keyMargin) ?? 24.0;
  }

  static Future<void> setInternalGap(double gap) async {
    await _preferences.setDouble(_keyInternalGap, gap);
  }

  static double getInternalGap() {
    return _preferences.getDouble(_keyInternalGap) ?? 16.0;
  }

  static Future<void> setColumnCount(int count) async {
    await _preferences.setInt(_keyColumnCount, count);
  }

  static int getColumnCount() {
    return _preferences.getInt(_keyColumnCount) ?? 1;
  }
}
