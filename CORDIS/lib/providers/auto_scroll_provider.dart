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
    for (int i = 0; i < _itemKeys.entries.length; i++) {
      final entry = _itemKeys.entries.elementAt(i);
      final itemContext = entry.value.currentContext;
      if (itemContext == null) continue;

      final box = itemContext.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final itemStart = scrollAxis == Axis.vertical
          ? box.localToGlobal(Offset.zero).dy
          : box.localToGlobal(Offset.zero).dx;

      if (itemStart > -viewportHeight * 0.05 &&
          itemStart < viewportHeight * 0.3) {
        currentSectionIndex = 0; // Reset section index when item changes
        return entry.key;
      }

      if (i < _itemKeys.entries.length - 1) {
        final nextEntry = _itemKeys.entries.elementAt(i + 1);
        final nextContext = nextEntry.value.currentContext;
        if (nextContext == null) continue;

        final nextBox = nextContext.findRenderObject() as RenderBox?;
        if (nextBox == null) continue;

        final nextItemStart = scrollAxis == Axis.vertical
            ? nextBox.localToGlobal(Offset.zero).dy
            : nextBox.localToGlobal(Offset.zero).dx;

        if (nextItemStart > viewportHeight * 0.5 &&
            nextItemStart < viewportHeight * 0.95) {
          currentSectionIndex = _sectionCount - 1;
          return entry.key;
        }
      }
    }
    return null;
  }

  void syncSectionFromViewport(double viewportHeight, Axis scrollAxis) {
    final currentContext =
        _sectionKeys[_currentItemIndex]?[currentSectionIndex]?.currentContext;

    final currentBox = currentContext?.findRenderObject() as RenderBox?;
    if (currentBox == null) throw Exception('Current section box not found');

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
