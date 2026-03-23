import 'dart:async';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:flutter/foundation.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/repositories/local/playlist_repository.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _playlistRepository = PlaylistRepository();

  PlaylistProvider();

  final Map<int, Playlist> _playlists = {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _hasUnsavedChanges = false;

  String? _error;

  // Getters
  Map<int, Playlist> get playlists => _playlists;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  List<int> get filteredPlaylists {
    if (_searchTerm.isEmpty) {
      return _playlists.keys.toList();
    } else {
      List<int> tempFiltered = [];
      for (var entry in _playlists.entries) {
        final playlist = entry.value;
        if (playlist.name.toLowerCase().contains(_searchTerm)) {
          tempFiltered.add(entry.key);
        }
      }
      return tempFiltered;
    }
  }

  String _searchTerm = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;

  String? get error => _error;

  Playlist? getPlaylist(int id) {
    return _playlists[id];
  }

  // ===== CREATE =====
  // Create a new playlist from local cache
  Future<void> createPlaylist(String playlistName, int userLocalId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final playlist = Playlist(
        name: playlistName,
        id: -1,
        createdBy: userLocalId,
      );
      int id = await _playlistRepository.insertPlaylist(playlist);

      // Add the created playlist with new ID directly to cache
      _playlists[id] = playlist.copyWith(id: id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Create a new playlist from the Domain model
  /// Used when duplicating a Schedule or Playlist
  Future<int> createPlaylistFromDomain(Playlist playlist) async {
    int playlistId;
    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      playlistId = await _playlistRepository.insertPlaylist(playlist);

      // Add the created playlist with new ID to cache
      _playlists[playlistId] = playlist.copyWith(id: playlistId);
    } catch (e) {
      _error = e.toString();
      playlistId = -1;
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    return playlistId;
  }

  // ===== READ =====
  // Load Playlists from local SQLite database
  Future<void> loadPlaylists() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final playlist = await _playlistRepository.getAllPlaylists();
      for (var p in playlist) {
        _playlists[p.id] = p;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Single Playlist by ID
  Future<void> loadPlaylist(int id) async {
    if (_isLoading) return;

    // If id is -1, it means we want to clear the current playlist
    // (used when discarding changes on a new playlist that hasn't been saved yet)
    if (id == -1) {
      _playlists.remove(-1);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Playlist playlist = (await _playlistRepository.getPlaylistById(
        id,
      ))!;

      _playlists[playlist.id] = playlist;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  /// Update a playlist with data currently on the cache (name/description/items)
  Future<void> saveFromCache(int playlistID) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final playlist = _playlists[playlistID];
      if (playlist != null) {
        await _playlistRepository.upsertPlaylistMetadata(playlist);
      }

      for (var item in playlist!.items) {
        switch (item.type) {
          case PlaylistItemType.version:
            if (item.id == null) {
              await _playlistRepository.addVersionToPlaylist(
                playlistID,
                item.contentId!,
              );
            } else {
              await _playlistRepository.updatePlaylistVersionPosition(
                item.id!,
                item.position,
              );
            }
            break;
          case PlaylistItemType.flowItem:
            // Handled in FlowItemProvider, no need to update here
            break;
        }
      }

      await loadPlaylist(playlistID);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== CACHE =====
  /// Update a Playlist with new data (name/description)
  void cacheName(int id, String name) {
    _playlists[id] = _playlists[id]!.copyWith(name: name);
  }

  /// Cache a version addition to a playlist (used for optimistic UI updates)
  void cacheAddVersion(int playlistId, int versionId) {
    final playlist = _playlists[playlistId];
    if (playlist != null) {
      final newItem = PlaylistItem.version(
        versionId: versionId,
        position: playlist.items.length,
      );
      playlist.items.add(newItem);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void cacheReposition(int playlistId, int oldPosition, int newPosition) {
    final playlist = _playlists[playlistId];
    if (playlist != null) {
      final items = playlist.items;
      if (oldPosition < items.length && newPosition < items.length) {
        final item = items.removeAt(oldPosition);
        items.insert(newPosition, item);
        _hasUnsavedChanges = true;
        notifyListeners();
      }
    }
  }

  void cacheDuplicateVersion(int playlistId, int versionId, int userLocalId) {
    final playlist = _playlists[playlistId];
    if (playlist != null) {
      final newItem = PlaylistItem.version(
        versionId: versionId,
        position: playlist.items.length,
      );
      playlist.items.add(newItem);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void cacheRemoveVersion(int itemID, int playlistID) {
    final playlist = _playlists[playlistID];
    if (playlist != null) {
      playlist.items.removeWhere((item) => item.id == itemID);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// Clears cached data and reset state
  void clearCache() {
    _playlists.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _isDeleting = false;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ===== DELETE =====
  // Delete a playlist
  Future<void> deletePlaylist(int playlistId) async {
    if (_isSaving) return;

    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      await _playlistRepository.deletePlaylist(playlistId);
      _playlists.remove(playlistId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ===== UTILITY =====
  /// Check if a version is still in the passed playlist (used to determine if it should be deleted entirely or not)
  bool versionIsInPlaylist(int versionId, int playlistId) {
    final playlist = _playlists[playlistId];
    if (playlist != null) {
      if (playlist.items.any((item) => item.contentId == versionId)) {
        return true;
      }
    }
    return false;
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ===== SEARCH =====
  void setSearchTerm(String searchTerm) {
    _searchTerm = searchTerm.toLowerCase();
    notifyListeners();
  }
}
