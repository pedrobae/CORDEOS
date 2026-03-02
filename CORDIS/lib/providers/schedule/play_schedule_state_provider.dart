import 'package:flutter/foundation.dart';

/// Lightweight provider for managing PlayScheduleScreen state
/// This allows tab navigation without rebuilding expensive widget trees
class PlayScheduleStateProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _showSettings = false;

  int get currentTabIndex => _currentTabIndex;
  bool get showSettings => _showSettings;

  void setCurrentTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void toggleSettings() {
    _showSettings = !_showSettings;
    notifyListeners();
  }

  void setShowSettings(bool value) {
    if (_showSettings != value) {
      _showSettings = value;
      notifyListeners();
    }
  }

  void reset() {
    _currentTabIndex = 0;
    _showSettings = false;
  }
}
