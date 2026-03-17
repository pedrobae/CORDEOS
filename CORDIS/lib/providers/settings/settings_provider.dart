import 'package:flutter/material.dart';
import 'package:cordis/utils/app_theme.dart';
import 'package:cordis/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isColorVariant = false;
  Locale _locale = const Locale('pt', 'BR');
  String _timeZone = 'UTC';
  String _country = '';
  bool _notificationsEnabled = true;
  bool _reminderNotifications = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isColorVariant => _isColorVariant;
  Locale get locale => _locale;
  String get timeZone => _timeZone;
  String get country => _country;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get reminderNotifications => _reminderNotifications;

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    _themeMode = SettingsService.getThemeMode();
    _isColorVariant = SettingsService.isColorVariant();
    _locale = SettingsService.getLocale();
    _timeZone = SettingsService.getTimeZone();
    _country = SettingsService.getCountry();
    _notificationsEnabled = SettingsService.getNotificationsEnabled();
    _reminderNotifications = SettingsService.getReminderNotifications();
    notifyListeners();
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await SettingsService.setThemeMode(mode);
    notifyListeners();
  }

  /// Set theme color and persist
  Future<void> toggleColorVariant() async {
    _isColorVariant = !_isColorVariant;
    await SettingsService.setColorVariant(_isColorVariant);
    notifyListeners();
  }

  /// Set locale and persist
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await SettingsService.setLocale(locale);
    notifyListeners();
  }

  /// Set timezone and persist
  Future<void> setTimeZone(String timeZone) async {
    _timeZone = timeZone;
    await SettingsService.setTimeZone(timeZone);
    notifyListeners();
  }

  Future<void> setCountry(String countryCode) async {
    _country = countryCode;
    await SettingsService.setCountry(_country);
    notifyListeners();
  }

  /// Toggle notifications and persist
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await SettingsService.setNotificationsEnabled(_notificationsEnabled);
    notifyListeners();
  }

  /// Set notifications enabled and persist
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await SettingsService.setNotificationsEnabled(enabled);
    notifyListeners();
  }

  /// Toggle reminder notifications and persist
  Future<void> toggleReminderNotifications() async {
    _reminderNotifications = !_reminderNotifications;
    await SettingsService.setReminderNotifications(_reminderNotifications);
    notifyListeners();
  }

  /// Set reminder notifications and persist
  Future<void> setReminderNotifications(bool enabled) async {
    _reminderNotifications = enabled;
    await SettingsService.setReminderNotifications(enabled);
    notifyListeners();
  }

  // Theme getters
  ThemeData get lightTheme => AppTheme.getTheme(_isColorVariant, false);
  ThemeData get darkTheme => AppTheme.getTheme(_isColorVariant, true);

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await SettingsService.clearAllSettings();
    await loadSettings();
  }
}
