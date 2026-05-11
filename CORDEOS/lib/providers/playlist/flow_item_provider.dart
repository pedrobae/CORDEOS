import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/repositories/local/flow_item_repository.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FlowItemProvider extends ChangeNotifier {
  final FlowItemRepository _flowItemRepo = FlowItemRepository();

  FlowItemProvider();

  final Map<int, FlowItem> _flowItems = {};
  final List<int> _cachedDeletions = [];
  final List<int> _cachedCreations = [];

  bool _hasUnsavedChanges = false;

  // Getters
  Map<int, FlowItem> get flowItems => _flowItems;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

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

  Future<void> ensureIsLoaded(int flowID) async {
    if (_flowItems[flowID] != null) return;
    loadFlowItem(flowID);
  }

  Future<void> loadFlowItem(int id) async {
    // Not in cache, query repository
    try {
      final flowItem = await _flowItemRepo.getFlowItem(id);
      if (flowItem != null) {
        _flowItems[id] = flowItem;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - ${e.toString()}");
    }
  }

  /// Fetches a flow item straight from SQLite, if exists
  Future<FlowItem?> fetchFlowItem(int id) async {
    return await _flowItemRepo.getFlowItem(id);
  }

  // ===== CREATE =====
  // Create a new FlowItem from scratch
  Future<void> create(FlowItem flowItem) async {
    try {
      final id = await _flowItemRepo.createFlowItem(flowItem);
      _cachedCreations.add(id);
      await loadFlowItem(id);
      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - ${e.toString()}");
    }
  }

  Future<int?> createFromCache(int id) async {
    int? newID;
    if (!_flowItems.containsKey(id)) return newID;
    try {
      final flowItem = _flowItems[id]!;
      newID = await _flowItemRepo.createFlowItem(flowItem);
      _cachedCreations.add(newID);
      await loadFlowItem(newID);
      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - ${e.toString()}");
    }
    return newID;
  }

  void initializeNewFlow(int playlistID, int position) {
    final newFlowItem = FlowItem(
      firebaseId: generateFirebaseId(),
      playlistId: playlistID,
      title: '',
      contentText: '',
      position: position,
      duration: Duration.zero,
    );
    _flowItems[-1] = newFlowItem; // Temporary Cache for item creation
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Duplicate a Flow Item by ID
  Future<void> duplicateFlowItem(
    int id,
    String titleSuffix,
    int position,
  ) async {
    try {
      final original = _flowItems[id];
      if (original == null) {
        throw Exception('Flow Item with ID $id not found for duplication.');
      }

      final duplicate = FlowItem(
        firebaseId:
            generateFirebaseId(), // Generate a new Firebase ID for the duplicate
        playlistId: original.playlistId,
        title: '${original.title} $titleSuffix',
        contentText: original.contentText,
        position: position,
        duration: original.duration,
      );

      int newId = await _flowItemRepo.createFlowItem(duplicate);
      await loadFlowItem(newId);

      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - ${e.toString()}");
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
    if (!_flowItems.containsKey(id)) return;
    try {
      final flowItem = _flowItems[id]!;

      await _flowItemRepo.updateFlowItem(
        id,
        title: flowItem.title,
        content: flowItem.contentText,
        position: flowItem.position,
        duration: flowItem.duration.inSeconds,
      );

      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - ${e.toString()}");
    }
  }

  // ===== DELETE =====
  // Delete a Flow Item by ID
  Future<void> deleteFlowItem(int id) async {
    try {
      await _flowItemRepo.deleteFlowItem(id);
      _flowItems.remove(id); // Remove from local cache
      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - ${e.toString()}");
    }
  }

  void cacheDeletion(int id) {
    _flowItems.remove(id);
    _cachedDeletions.add(id);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<void> persistDeletions() async {
    try {
      debugPrint("FLOW PROVIDER - persisting deletion of flow items");
      for (var id in _cachedDeletions) {
        debugPrint("\t ID - $id");
        await _flowItemRepo.deleteFlowItem(id);
      }
      _cachedDeletions.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("FLOW ITEM PROVIDER - error deleting flow - $e");
    }
  }

  void removeFromCache(int id) {
    _flowItems.remove(id);
    _cachedCreations.remove(id);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ===== UTILITY =====
  // Clear cached data and reset state
  void clearCache() {
    _flowItems.clear();
    _cachedCreations.clear();
    _cachedDeletions.clear();
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void deleteCachedCreations() async {
    _hasUnsavedChanges = false;
    for (var id in _cachedCreations) {
      debugPrint(
        "FLOW PROVIDER - clearing unsaved changes, deleting new flow item with ID $id",
      );
      await _flowItemRepo.deleteFlowItem(id);
    }
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
    _cachedCreations.clear();
    _cachedDeletions.clear();
    notifyListeners();
  }
}
