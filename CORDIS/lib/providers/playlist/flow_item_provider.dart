import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/repositories/local/flow_item_repository.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FlowItemProvider extends ChangeNotifier {
  final FlowItemRepository _flowItemRepo = FlowItemRepository();

  FlowItemProvider();

  final Map<int, FlowItem> _flowItems = {};

  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  // Getters
  Map<int, FlowItem> get flowItems => _flowItems;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get error => _error;

  // ===== READ =====

  Future<String?> getFirebaseIdByLocalId(int localId) async {
    // Check cache first
    if (_flowItems.containsKey(localId)) {
      return _flowItems[localId]!.firebaseId;
    }
    // Not in cache, query repository
    final flowItem = await _flowItemRepo.getFlowItem(localId);
    return flowItem?.firebaseId;
  }

  Future<int?> getLocalIdByFirebaseId(String firebaseId) async {
    if (firebaseId.isEmpty) return null;
    // Check cache first
    for (final entry in _flowItems.entries) {
      if (entry.value.firebaseId == firebaseId) {
        return entry.key;
      }
    }
    // Not in cache, query repository
    final flowItem = await _flowItemRepo.getFlowItemByFirebaseId(firebaseId);
    return flowItem?.id;
  }

  FlowItem? getFlowItem(int id) {
    // Check cache first
    if (_flowItems.containsKey(id)) {
      return _flowItems[id];
    }

    return null;
  }

  Future<void> loadFlowItem(int id) async {
    // Not in cache, query repository
    final flowItem = await _flowItemRepo.getFlowItem(id);
    if (flowItem != null) {
      _flowItems[id] = flowItem;
    }
    notifyListeners();
  }

  /// Fetches a flow item straight from SQLite, if exists
  Future<FlowItem?> fetchFlowItem(int id) async {
    return await _flowItemRepo.getFlowItem(id);
  }

  // ===== CREATE =====
  // Create a new FlowItem from scratch
  Future<void> create(FlowItem flowItem) async {
    if (_isSaving) return;

    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      final id = await _flowItemRepo.createFlowItem(flowItem);
      await loadFlowItem(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void initializeNewFlow(int playlistID, int position) {
    final newFlowItem = FlowItem(
      firebaseId: '',
      playlistId: playlistID,
      title: '',
      contentText: '',
      position: position,
      duration: Duration.zero,
    );
    _flowItems[-1] = newFlowItem; // Temporary Cache for item creation
  }

  /// Duplicate a Flow Item by ID
  Future<void> duplicateFlowItem(
    int id,
    String titleSuffix,
    int position,
  ) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final original = _flowItems[id];
      if (original == null) {
        throw Exception('Flow Item with ID $id not found for duplication.');
      }

      final duplicate = FlowItem(
        firebaseId: '', // Dont copy Firebase ID for new item
        playlistId: original.playlistId,
        title: '${original.title} $titleSuffix',
        contentText: original.contentText,
        position: position,
        duration: original.duration,
      );

      int newId = await _flowItemRepo.createFlowItem(duplicate);
      await loadFlowItem(newId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  /// Cache Duration update for a Flow Item
  void cacheDuration(int id, Duration newDuration) {
    if (_flowItems.containsKey(id)) {
      _flowItems[id] = _flowItems[id]!.copyWith(duration: newDuration);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// Caches title update for a Flow Item
  void cacheTitle(int id, String newTitle) {
    if (_flowItems.containsKey(id)) {
      _flowItems[id] = _flowItems[id]!.copyWith(title: newTitle);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// Caches content text update for a Flow Item
  void cacheContent(int id, String newContent) {
    if (_flowItems.containsKey(id)) {
      _flowItems[id] = _flowItems[id]!.copyWith(contentText: newContent);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// Persist cached changes of a Flow Item to the database
  Future<void> save(int id) async {
    if (_isSaving) return;
    if (!_flowItems.containsKey(id)) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final flowItem = _flowItems[id]!;

      if (id == -1) {
        // New Flow Item creation
        final newId = await _flowItemRepo.createFlowItem(flowItem);
        await loadFlowItem(newId);
        _flowItems.remove(-1); // Clear temporary cache
      } else {
        await _flowItemRepo.updateFlowItem(
          id,
          title: flowItem.title,
          content: flowItem.contentText,
          position: flowItem.position,
          duration: flowItem.duration.inSeconds,
        );
      }
      _hasUnsavedChanges = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  // Delete a Flow Item by ID
  Future<void> deleteFlowItem(int id) async {
    if (_isDeleting) return;

    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      await _flowItemRepo.deleteFlowItem(id);
      _flowItems.remove(id); // Remove from local cache
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ===== UTILITY =====
  // Clear cached data and reset state
  void clearCache() {
    _flowItems.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _isDeleting = false;
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
    notifyListeners();
  }
}
