import 'dart:async';

import 'package:cordis/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AutoScrollProvider extends ChangeNotifier {
  AutoScrollProvider() {
    _loadSettings();
  }

  double scrollSpeed = 1.0;
  static const int _millisecondsPerLine = 1500;

  bool isAutoScrolling = false;
  bool scrollModeEnabled = false;

  int _currentItemIndex = 0;
  int _currentSectionIndex = 0;

  Timer? autoScrollTimer;
  Timer? _progressTimer;
  DateTime? _timerStartTime;
  final ValueNotifier<double> _timerProgress = ValueNotifier<double>(0.0);

  ValueListenable<double> get timerProgressListenable => _timerProgress;

  final Map<int, GlobalKey> _itemKeys = {};
  final Map<int, Map<int, GlobalKey>> _sectionKeys = {};

  final Map<int, Map<int, int>> _sectionLineCounts = {};

  Map<int, GlobalKey> get currentItemSectionKeys =>
      _sectionKeys[_currentItemIndex] ?? {};

  int get _sectionCount => currentItemSectionKeys.length;
  int get currentSectionIndex => _currentSectionIndex;
  int get currentItemIndex => _currentItemIndex;

  set currentSectionIndex(int value) {
    if (_currentSectionIndex == value) return;
    _currentSectionIndex = value;
    notifyListeners();
  }

  set currentItemIndex(int value) {
    if (_currentItemIndex == value) return;
    _currentItemIndex = value;
    notifyListeners();
  }

  // ===== SETTINGS METHODS =====
  /// Gets settings from SettingsService and updates provider state
  Future<void> _loadSettings() async {
    _currentSectionIndex = 0;
    _currentItemIndex = 0;
    scrollModeEnabled = SettingsService.getAutoScrollEnabled();
    scrollSpeed = SettingsService.getAutoScrollSpeed();
    notifyListeners();
  }

  /// Updates scroll speed and saves to settings
  void setScrollSpeed(double value) {
    scrollSpeed = value;
    SettingsService.setAutoScrollSpeed(value);
    notifyListeners();
  }

  void toggleScrollMode() {
    scrollModeEnabled = !scrollModeEnabled;
    stopAutoScroll();
    SettingsService.setAutoScrollEnabled(scrollModeEnabled);
    notifyListeners();
  }

  GlobalKey registerItem(int itemIndex) {
    return _itemKeys.putIfAbsent(itemIndex, GlobalKey.new);
  }

  GlobalKey registerSection(int itemIndex, int sectionIndex) {
    final itemSections = _sectionKeys.putIfAbsent(itemIndex, () => {});
    return itemSections.putIfAbsent(sectionIndex, GlobalKey.new);
  }

  void setSectionLineCount(int itemIndex, int sectionIndex, int lineCount) {
    final itemLineCounts = _sectionLineCounts.putIfAbsent(itemIndex, () => {});
    itemLineCounts[sectionIndex] = lineCount;
  }

  // ===== AUTO SCROLL METHODS =====
  /// Toggles auto-scroll on/off and starts/stops timer accordingly
  void toggleAutoScroll() {
    if (!scrollModeEnabled || isAutoScrolling) {
      stopAutoScroll();
    } else {
      startAutoScroll();
    }
  }

  void stopAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _timerStartTime = null;
    _timerProgress.value = 0.0;
    isAutoScrolling = false;
    notifyListeners();
  }

  /// Starts the auto-scroll timer
  /// Which scrolls through sections at intervals based on line count and scrollSpeed
  void startAutoScroll() {
    if (!scrollModeEnabled) return;
    if (isAutoScrolling) return;
    if (_sectionCount == 0) return;

    isAutoScrolling = true;
    notifyListeners();

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _timerProgress.value = timerProgress;
    });

    _scheduleNextSectionScroll();
  }

  /// Schedules the next section scroll based on current section's line count
  /// Uses a single-shot timer that recalculates duration for each section
  void _scheduleNextSectionScroll() {
    if (_sectionCount == 0 || !isAutoScrolling) return;

    final lineCount = _activeLineCounts[currentSectionIndex];
    if (lineCount == null || lineCount <= 0) return;

    final durationPerSection = Duration(
      milliseconds: (_millisecondsPerLine * lineCount ~/ scrollSpeed).toInt(),
    );

    _timerStartTime = DateTime.now();

    // Cancel existing timer and schedule next section scroll
    autoScrollTimer?.cancel();
    autoScrollTimer = Timer(durationPerSection, () {
      if (_sectionCount == 0 || !isAutoScrolling) return;

      // Move to next section
      if (currentSectionIndex < _sectionCount - 1) {
        currentSectionIndex++;
        scrollToItemSection(
          itemIndex: _currentItemIndex,
          sectionIndex: currentSectionIndex,
        );
        _scheduleNextSectionScroll(); // Schedule next with its line count
      } else {
        // Stop at the end
        stopAutoScroll();
      }
    });
  }

  /// Scrolls to the section at the given index using its GlobalKey
  /// Scrolls to the section at the given indexes using its GlobalKey
  void scrollToItemSection({
    required int itemIndex,
    required int sectionIndex,
  }) {
    if (_sectionKeys[itemIndex] == null) return;
    if (_sectionKeys[itemIndex]![sectionIndex] == null) return;

    final sectionKey = _sectionKeys[itemIndex]![sectionIndex];
    final context = sectionKey!.currentContext;

    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position section 20% from top
      );
    }

    _currentItemIndex = itemIndex;
    currentSectionIndex = sectionIndex;
  }

  // ===== HELPER METHODS =====
  /// Returns a value between 0.0 and 1.0 representing progress to next section scroll
  double get timerProgress {
    if (autoScrollTimer == null ||
        !autoScrollTimer!.isActive ||
        _timerStartTime == null) {
      return 0.0;
    }

    final lineCount = _activeLineCounts[currentSectionIndex];
    if (lineCount == null || lineCount <= 0) {
      return 0.0;
    }

    final durationPerSection = Duration(
      milliseconds: (_millisecondsPerLine * lineCount ~/ scrollSpeed).toInt(),
    );

    // Calculate elapsed time since timer started
    final elapsed = DateTime.now().difference(_timerStartTime!);
    final elapsedMs = elapsed.inMilliseconds;

    // Return progress within current interval (0.0 to 1.0)
    return (elapsedMs % durationPerSection.inMilliseconds) /
        durationPerSection.inMilliseconds;
  }

  /// Calculates the current section index based on the scroll offset
  int? syncItemFromViewport(double viewportHeight, Axis scrollAxis) {
    debugPrint('$viewportHeight');
    bool hasItemsPre = true;
    bool hasItemsPost = true;
    int currentIndex = currentItemIndex;
    int indexOffset = 1;
    bool checkPreNext = true;

    if (itemCoversScreen(currentItemIndex, viewportHeight, scrollAxis)) {
      return currentItemIndex;
    }

    int loopCount = 0;
    while (hasItemsPost || hasItemsPre || loopCount > 100) {
      loopCount++;
      if (checkPreNext) {
        currentIndex = currentIndex - indexOffset;
        indexOffset++;

        if (hasItemsPost) {
          checkPreNext = false;
        }

        if (currentIndex < 0) {
          hasItemsPre = false;
          continue;
        }

        if (itemCoversScreen(currentIndex, viewportHeight, scrollAxis)) {
          return currentIndex;
        }
      } else {
        currentIndex = currentIndex + indexOffset;

        if (hasItemsPre) {
          checkPreNext = true;
        }

        if (currentIndex >= _itemKeys.length) {
          hasItemsPost = false;
          continue;
        }
        if (itemCoversScreen(currentIndex, viewportHeight, scrollAxis)) {
          return currentIndex;
        }
      }
    }

    return null;
  }

  /// Checks if the item at index i covers most of the viewport
  /// Gets the relevant edges depending on scroll axis and checks
  bool itemCoversScreen(int i, double viewportHeight, Axis scrollAxis) {
    final itemKey = _itemKeys[i];
    if (itemKey == null) return false;

    final context = itemKey.currentContext;
    if (context == null) return false;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return false;

    final itemFront = scrollAxis == Axis.vertical
        ? box.localToGlobal(Offset.zero).dy
        : box.localToGlobal(Offset.zero).dx;

    final itemBack = scrollAxis == Axis.vertical
        ? box.localToGlobal(Offset.zero).dy + box.size.height
        : box.localToGlobal(Offset.zero).dx + box.size.width;

    debugPrint(
      '$i | front - $itemFront | back - $itemBack | viewHeight - $viewportHeight',
    );

    if (itemFront < viewportHeight * 0.20 && itemBack > viewportHeight * 0.80) {
      return true;
    }

    return false;
  }

  void syncSectionFromViewport(double viewportHeight, Axis scrollAxis) {
    final currentContext =
        _sectionKeys[_currentItemIndex]?[currentSectionIndex]?.currentContext;

    final currentBox = currentContext?.findRenderObject() as RenderBox?;
    if (currentBox == null) return;

    final currentEdge = scrollAxis == Axis.vertical
        ? currentBox.localToGlobal(Offset.zero).dy
        : currentBox.localToGlobal(Offset.zero).dx;

    if (currentEdge > viewportHeight * 0.10 &&
        currentEdge < viewportHeight * 0.40) {
      return;
    }

    for (final entry in currentItemSectionKeys.entries) {
      final sectionContext = entry.value.currentContext;
      if (sectionContext == null) continue;

      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final sectionEdge = scrollAxis == Axis.vertical
          ? box.localToGlobal(Offset.zero).dy
          : box.localToGlobal(Offset.zero).dx;

      if (sectionEdge > viewportHeight * 0.10 &&
          sectionEdge < viewportHeight * 0.40) {
        currentSectionIndex = entry.key;
        return;
      }
    }
  }

  Map<int, int> get _activeLineCounts =>
      _sectionLineCounts[_currentItemIndex] ?? {};

  /// Clears cache
  void clearCache({bool resetItemIndex = true}) {
    _itemKeys.clear();
    _sectionKeys.clear();
    _sectionLineCounts.clear();
    _currentSectionIndex = 0;
    if (resetItemIndex) {
      _currentItemIndex = 0;
    }
    _progressTimer?.cancel();
    _timerStartTime = null;
    _timerProgress.value = 0.0;
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    isAutoScrolling = false;
  }

  // ===== CLEANUP =====
  @override
  void dispose() {
    autoScrollTimer?.cancel();
    _progressTimer?.cancel();
    _timerProgress.dispose();
    super.dispose();
  }
}
