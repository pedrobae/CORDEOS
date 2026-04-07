import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // App Settings Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyIsColorVariant = 'is_color_variant';
  static const String _keyLocale = 'locale';
  static const String _keyTimeZone = 'time_zone';
  static const String _keyCountry = 'country';

  // Layout Settings Keys
  static const String _keyFontSize = 'layout_font_size';
  static const String _keyFontFamily = 'layout_font_family';

  static const String _keyScrollDirection = 'layout_scroll_direction';
  static const String _keyCardWidthMult = 'layout_card_width_mult';

  static const String _keyShowSectionHeaders = 'layout_show_section_headers';
  static const String _keyDenseCipherCard = 'layout_dense_cipher_card';

  static const String _keyLineSpacing = 'layout_line_spacing';
  static const String _keyLineBreakSpacing = 'layout_line_break_spacing';
  static const String _keyChordLyricSpacing = 'layout_chord_lyric_spacing';
  static const String _keyMinChordSpacing = 'layout_min_chord_spacing';
  static const String _keyLetterSpacing = 'layout_letter_spacing';

  // Filter Settings Keys
  static const String _keyShowChords = 'layout_show_chords';
  static const String _keyShowLyrics = 'layout_show_lyrics';
  static const String _keyShowNotes = 'layout_show_notes';
  static const String _keyShowTransitions = 'layout_show_transitions';
  static const String _keyShowTextSections = 'layout_show_text_sections';
  static const String _keyShowRepeatSections = 'layout_show_repeat_sections';

  // Scroll Settings Keys
  static const String _keyAutoScrollEnabled = 'layout_auto_scroll_enabled';
  static const String _keyAutoScrollSpeed = 'layout_auto_scroll_speed';
  static const String _keyTransparentScrollButtons =
      'layout_transparent_scroll_buttons';

  // Notification Settings Keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderNotifications = 'reminder_notifications';

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

  // ====== APP SETTINGS ======

  /// Save theme mode
  static Future<void> setThemeMode(ThemeMode mode) async {
    await _preferences.setString(_keyThemeMode, mode.name);
  }

  /// Get theme mode
  static ThemeMode getThemeMode() {
    final value = _preferences.getString(_keyThemeMode) ?? 'system';
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  /// Save theme color
  static Future<void> setColorVariant(bool isVariant) async {
    await _preferences.setBool(_keyIsColorVariant, isVariant);
  }

  /// Get theme color
  static bool isColorVariant() {
    final value = _preferences.getBool(_keyIsColorVariant) ?? false;
    return value;
  }

  /// Save locale
  static Future<void> setLocale(Locale locale) async {
    await _preferences.setString(_keyLocale, locale.toString());
  }

  /// Get locale
  static Locale getLocale() {
    final localeString = _preferences.getString(_keyLocale) ?? 'pt_BR';
    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(parts[0]);
    }
  }

  /// Save time zone
  static Future<void> setTimeZone(String timeZone) async {
    await _preferences.setString(_keyTimeZone, timeZone);
  }

  /// Get time zone
  static String getTimeZone() {
    return _preferences.getString(_keyTimeZone) ?? 'UTC';
  }

  /// Save country
  static Future<void> setCountry(String country) async {
    await _preferences.setString(_keyCountry, country);
  }

  /// Get country
  static String getCountry() {
    return _preferences.getString(_keyCountry) ?? '';
  }

  // ====== LAYOUT SETTINGS ======

  /// Save font size
  static Future<void> setFontSize(double fontSize) async {
    await _preferences.setDouble(_keyFontSize, fontSize);
  }

  /// Get font size
  static double getFontSize() {
    return _preferences.getDouble(_keyFontSize) ?? 16.0;
  }

  /// Save font family
  static Future<void> setFontFamily(String fontFamily) async {
    await _preferences.setString(_keyFontFamily, fontFamily);
  }

  /// Get font family
  static String getFontFamily() {
    return _preferences.getString(_keyFontFamily) ?? 'OpenSans';
  }

  /// Save scroll direction
  static Future<void> setScrollDirection(Axis direction) async {
    await _preferences.setString(_keyScrollDirection, direction.toString());
  }

  /// Get scroll direction
  static Axis getScrollDirection() {
    final value =
        _preferences.getString(_keyScrollDirection) ?? Axis.vertical.toString();
    return Axis.values.firstWhere(
      (axis) => axis.toString() == value,
      orElse: () => Axis.vertical,
    );
  }

  static Future<void> setShowSectionHeaders(bool show) async {
    await _preferences.setBool(_keyShowSectionHeaders, show);
  }

  static bool getShowSectionHeaders() {
    return _preferences.getBool(_keyShowSectionHeaders) ?? true;
  }

  static Future<void> setCardWidthMult(double value) async {
    await _preferences.setDouble(_keyCardWidthMult, value);
  }

  static double getCardWidthMult() {
    return _preferences.getDouble(_keyCardWidthMult) ?? 1.0;
  }

  static Future<void> setDenseCipherCard(bool value) async {
    await _preferences.setBool(_keyDenseCipherCard, value);
  }

  static bool getDenseCipherCard() {
    return _preferences.getBool(_keyDenseCipherCard) ?? true;
  }

  // === advanced layout settings ===
  static Future<void> setLineSpacing(double value) async {
    await _preferences.setDouble(_keyLineSpacing, value);
  }

  static double getLineSpacing() {
    return _preferences.getDouble(_keyLineSpacing) ?? 0.0;
  }

  static Future<void> setLineBreakSpacing(double value) async {
    await _preferences.setDouble(_keyLineBreakSpacing, value);
  }

  static double getLineBreakSpacing() {
    return _preferences.getDouble(_keyLineBreakSpacing) ?? 0.0;
  }

  static Future<void> setChordLyricSpacing(double value) async {
    await _preferences.setDouble(_keyChordLyricSpacing, value);
  }

  static double getChordLyricSpacing() {
    return _preferences.getDouble(_keyChordLyricSpacing) ?? 0.0;
  }

  static Future<void> setMinChordSpacing(double value) async {
    await _preferences.setDouble(_keyMinChordSpacing, value);
  }

  static double getMinChordSpacing() {
    return _preferences.getDouble(_keyMinChordSpacing) ?? 4.0;
  }

  static Future<void> setLetterSpacing(double value) async {
    await _preferences.setDouble(_keyLetterSpacing, value);
  }

  static double getLetterSpacing() {
    return _preferences.getDouble(_keyLetterSpacing) ?? 0.0;
  }

  // ====== FILTER SETTINGS ======

  /// Save show chords
  static Future<void> setShowChords(bool show) async {
    await _preferences.setBool(_keyShowChords, show);
  }

  /// Get show chords
  static bool getShowChords() {
    return _preferences.getBool(_keyShowChords) ?? true;
  }

  /// Save show lyrics
  static Future<void> setShowLyrics(bool show) async {
    await _preferences.setBool(_keyShowLyrics, show);
  }

  /// Get show lyrics
  static bool getShowLyrics() {
    return _preferences.getBool(_keyShowLyrics) ?? true;
  }

  /// Save show notes
  static Future<void> setShowNotes(bool show) async {
    await _preferences.setBool(_keyShowNotes, show);
  }

  /// Get show notes
  static bool getShowNotes() {
    return _preferences.getBool(_keyShowNotes) ?? true;
  }

  /// Save show transitions
  static Future<void> setShowTransitions(bool show) async {
    await _preferences.setBool(_keyShowTransitions, show);
  }

  /// Get show transitions
  static bool getShowTransitions() {
    return _preferences.getBool(_keyShowTransitions) ?? true;
  }

  /// Save show text sections
  static Future<void> setShowTextSections(bool show) async {
    await _preferences.setBool(_keyShowTextSections, show);
  }

  /// Get show text sections
  static bool getShowTextSections() {
    return _preferences.getBool(_keyShowTextSections) ?? true;
  }

  /// Save show repeat sections
  static Future<void> setShowRepeatSections(bool show) async {
    await _preferences.setBool(_keyShowRepeatSections, show);
  }

  /// Get show repeat sections
  static bool getShowRepeatSections() {
    return _preferences.getBool(_keyShowRepeatSections) ?? true;
  }

  // === SCROLL SETTINGS ===
  /// Save auto scroll enabled
  static Future<void> setAutoScrollEnabled(bool enabled) async {
    await _preferences.setBool(_keyAutoScrollEnabled, enabled);
  }

  /// Get auto scroll enabled
  static bool getAutoScrollEnabled() {
    return _preferences.getBool(_keyAutoScrollEnabled) ?? true;
  }

  /// Save auto scroll speed
  static Future<void> setAutoScrollSpeed(double speed) async {
    await _preferences.setDouble(_keyAutoScrollSpeed, speed);
  }

  /// Get auto scroll speed
  static double getAutoScrollSpeed() {
    return _preferences.getDouble(_keyAutoScrollSpeed) ?? 1.0;
  }

  /// Save transparent scroll buttons
  static Future<void> setTransparentScrollButtons(bool transparent) async {
    await _preferences.setBool(_keyTransparentScrollButtons, transparent);
  }

  /// Get transparent scroll buttons
  static bool getTransparentScrollButtons() {
    return _preferences.getBool(_keyTransparentScrollButtons) ?? true;
  }

  // === NOTIFICATION SETTINGS ===

  /// Save notifications enabled
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _preferences.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Get notifications enabled
  static bool getNotificationsEnabled() {
    return _preferences.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Save reminder notifications
  static Future<void> setReminderNotifications(bool enabled) async {
    await _preferences.setBool(_keyReminderNotifications, enabled);
  }

  /// Get reminder notifications
  static bool getReminderNotifications() {
    return _preferences.getBool(_keyReminderNotifications) ?? true;
  }

  // === UTILITY METHODS ===
  /// Clear all settings (useful for debugging)
  static Future<void> clearAllSettings() async {
    await _preferences.clear();
  }
}
