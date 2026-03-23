import 'package:cordis/repositories/local/playlist_repository.dart';
import 'package:flutter/foundation.dart';

class SelectionProvider extends ChangeNotifier {
  PlaylistRepository playlistRepository = PlaylistRepository();

  bool _isSelectionMode = false;
  int? _targetId; // Playlist ID
  final List<dynamic> _selectedItemIds =
      []; // int for local version / String for cloud version

  // Versions that will be deleted on change discard
  final List<int> _newlyAddedVersionIds = [];

  bool get isSelectionMode => _isSelectionMode;
  List<int> get newlyAddedVersionIds => _newlyAddedVersionIds;
  List<dynamic> get selectedItemIds => _selectedItemIds;
  int? get targetId => _targetId;

  void enableSelectionMode({dynamic targetId}) {
    _isSelectionMode = true;
    if (targetId != null) {
      _targetId = targetId;
    }
    notifyListeners();
  }

  void disableSelectionMode() {
    _isSelectionMode = false;
    _selectedItemIds.clear();
    _targetId = null;
    notifyListeners();
  }

  void select(dynamic item) {
    _selectedItemIds.add(item);
    notifyListeners();
  }

  void deselect(dynamic item) {
    _selectedItemIds.remove(item);
    notifyListeners();
  }

  void setTarget(int id) {
    _targetId = id;
  }

  void clearTarget() {
    _targetId = null;
  }

  bool isSelected(dynamic item) {
    return _selectedItemIds.contains(item);
  }

  void clearSelection() {
    _selectedItemIds.clear();
    notifyListeners();
  }

  void addVersionIdToDelete(int versionId) {
    _newlyAddedVersionIds.add(versionId);
  }

  void clearNewlyAddedVersionIds() {
    _newlyAddedVersionIds.clear();
  }
}
