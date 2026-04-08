import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:flutter/foundation.dart';

/// Lightweight provider for managing PlayScheduleScreen state
/// This allows item navigation without rebuilding expensive widget trees
class PlayStateProvider extends ChangeNotifier {
  int _currentItemIndex = 0;
  int _itemCount = 0;
  List<PlaylistItem> _items = [];

  bool _showSettings = false;
  bool _showButtons = false;

  int get currentItemIndex => _currentItemIndex;
  int get itemCount => _itemCount;
  PlaylistItem? get currentItem {
    if (_currentItemIndex >= 0 && _currentItemIndex < _items.length) {
      return _items[_currentItemIndex];
    }
    return null;
  }

  PlaylistItem? get nextItem {
    if (_currentItemIndex + 1 >= 0 && _currentItemIndex + 1 < _items.length) {
      return _items[_currentItemIndex + 1];
    }
    return null;
  }

  List<PlaylistItem> get items => _items;

  bool get showSettings => _showSettings;
  bool get showButtons => _showButtons;

  PlaylistItem? getItemAt(int index) {
    if (index < 0 || index >= _items.length) return null;
    return _items[index];
  }

  set currentItemIndex(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_currentItemIndex == index) return;

    _currentItemIndex = index;
    notifyListeners();
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

  void appendItem(PlaylistItem item) {
    _items.add(item);
    notifyListeners();
  }

  void setItemCount(int count) {
    _itemCount = count;
    notifyListeners();
  }

  void reset() {
    _currentItemIndex = 0;
    _itemCount = 0;
    _showSettings = false;
    _showButtons = false;
    _items = [];
  }

  void showButtonsTemporarily() {
    _showButtons = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _showButtons = false;
      notifyListeners();
    });
  }
}
