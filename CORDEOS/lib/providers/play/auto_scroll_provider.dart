import 'dart:async';

import 'package:cordeos/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScrollProvider extends ChangeNotifier {
  ScrollProvider() {
    _loadSettings();
  }

  double scrollSpeed = 1.0;
  static const int _millisecondsPerLine = 1500;

  bool isAutoScrolling = false;
  bool scrollModeEnabled = false;
  bool transparentButtons = true;

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

  // ScrollController for manual scroll operations when items aren't built
  ScrollController? _scrollController;
  double _probeDistance = 800.0; // Fallback estimate

  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  void updateEstimatedItemHeight(double height) {
    _probeDistance = height;
  }

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
    transparentButtons = SettingsService.getTransparentScrollButtons();
    scrollSpeed = SettingsService.getAutoScrollSpeed();
    notifyListeners();
  }

  /// Updates scroll speed and saves to settings
  void setScrollSpeed(double value) {
    scrollSpeed = value;
    SettingsService.setAutoScrollSpeed(value);
    notifyListeners();
  }

  void toggleAutoScrollMode() {
    scrollModeEnabled = !scrollModeEnabled;
    stopAutoScroll();
    SettingsService.setAutoScrollEnabled(scrollModeEnabled);
    notifyListeners();
  }

  void disableAutoScrollMode() {
    scrollModeEnabled = false;
    stopAutoScroll();
    notifyListeners();
  }

  void toggleTransparentButtons() {
    transparentButtons = !transparentButtons;
    SettingsService.setTransparentScrollButtons(transparentButtons);
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

        final sectionKey =
            _sectionKeys[_currentItemIndex]?[currentSectionIndex];
        final sectionContext = sectionKey?.currentContext;

        if (sectionContext != null && sectionContext.mounted) {
          Scrollable.ensureVisible(
            sectionContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
        _scheduleNextSectionScroll(); // Schedule next with its line count
      } else {
        // Stop at the end
        stopAutoScroll();
      }
    });
  }

  /// Scrolls to the next section
  void scrollToNextSection({required bool forward}) {
    if (_sectionCount == 0) return;

    final nextSectionIndex = currentSectionIndex + (forward ? 1 : -1);
    if (nextSectionIndex < _sectionCount && nextSectionIndex >= 0) {
      // Next section is within current item - scroll to it
      currentSectionIndex = nextSectionIndex;
      final sectionKey = _sectionKeys[_currentItemIndex]?[_currentSectionIndex];
      final sectionContext = sectionKey?.currentContext;

      if (sectionContext != null && sectionContext.mounted) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      }
    } else {
      // Next section is in next item - assume built check if next item exists
      final nextItemIndex = _currentItemIndex + (forward ? 1 : -1);
      if (nextItemIndex < _itemKeys.length && nextItemIndex >= 0) {
        // Next item exists - scroll
        currentSectionIndex = forward
            ? 0
            : _sectionKeys[nextItemIndex]!.length - 1;
        _currentItemIndex = nextItemIndex;

        final sectionKey =
            _sectionKeys[_currentItemIndex]?[_currentSectionIndex];
        final sectionContext = sectionKey?.currentContext;

        if (sectionContext != null && sectionContext.mounted) {
          Scrollable.ensureVisible(
            sectionContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.2,
          );
        }
      }
      // End of playlist - do nothing
    }
  }

  /// Recursive method that probes whether the target item / section is built,
  /// If not, scrolls toward it and probes again after postFrameCallback.
  void probeScrollToItem(int targetItemIndex, int targetSectionIndex) {
    // Try to get section context
    final sectionKey = _sectionKeys[targetItemIndex]?[targetSectionIndex];
    final sectionContext = sectionKey?.currentContext;

    if (sectionContext != null && sectionContext.mounted) {
      if (_currentItemIndex != targetItemIndex) {
        _currentItemIndex = targetItemIndex;
        notifyListeners();
      }
      if (_currentSectionIndex != targetSectionIndex) {
        _currentSectionIndex = targetSectionIndex;
        notifyListeners();
      }
      // Section is built - scroll directly to it
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
      return;
    }

    // Section not built - try scrolling to item first
    final itemKey = _itemKeys[targetItemIndex];
    final itemContext = itemKey?.currentContext;

    if (itemContext != null && itemContext.mounted) {
      // Item is built but section isn't registered yet - scroll to item
      if (_currentItemIndex != targetItemIndex) {
        _currentItemIndex = targetItemIndex;
        notifyListeners();
      }
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.2,
      ).then((_) {
        // After scroll completes, try section again
        WidgetsBinding.instance.addPostFrameCallback((_) {
          probeScrollToItem(targetItemIndex, targetSectionIndex);
        });
      });
      return;
    }

    // Neither item nor section is built - use scroll controller to scroll
    // toward the target item, which will trigger lazy loading
    if (_scrollController != null && _scrollController!.hasClients) {
      final currentOffset = _scrollController!.offset;
      final direction = targetItemIndex > _currentItemIndex ? 1.0 : -1.0;
      final targetOffset = currentOffset + (direction * _probeDistance);

      _scrollController!
          .animateTo(
            targetOffset.clamp(
              _scrollController!.position.minScrollExtent,
              _scrollController!.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.linear,
          )
          .then((_) {
            // After scroll, item should be built - retry navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              probeScrollToItem(targetItemIndex, targetSectionIndex);
            });
          });
      return;
    }
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
    bool hasItemsPre = true;
    bool hasItemsPost = true;
    int currentIndex = currentItemIndex;
    int indexOffset = 1;
    bool checkPreNext = true;

    if (itemCoversScreen(currentItemIndex, viewportHeight, scrollAxis)) {
      return currentItemIndex;
    }

    int loopCount = 0;
    while ((hasItemsPost || hasItemsPre) && loopCount <= 100) {
      indexOffset++;
      loopCount++;
      if (checkPreNext) {
        if (hasItemsPost) {
          currentIndex = currentIndex - indexOffset;
          checkPreNext = false;
        } else {
          currentIndex--;
        }

        if (currentIndex < 0) {
          hasItemsPre = false;
          continue;
        }

        if (itemCoversScreen(currentIndex, viewportHeight, scrollAxis)) {
          return currentIndex;
        }
      } else {
        if (hasItemsPre) {
          currentIndex = currentIndex + indexOffset;
          checkPreNext = true;
        } else {
          currentIndex++;
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

    if (itemFront < viewportHeight * 0.30 && itemBack > viewportHeight * 0.70) {
      return true;
    }

    return false;
  }

  void syncSectionFromViewport(double viewportHeight, Axis scrollAxis) {
    if (percentageOnScreen(currentSectionIndex, viewportHeight, scrollAxis) >
        0.8) {
      return;
    }
    bool hasSectionsPre = true;
    bool hasSectionsPost = true;
    int currentIndex = currentSectionIndex;
    int indexOffset = 0;
    bool checkPreNext = true;
    int loopCount = 0;
    while ((hasSectionsPost || hasSectionsPre) && loopCount <= 20) {
      indexOffset++;
      loopCount++;
      if (checkPreNext) {
        if (hasSectionsPost) {
          currentIndex = currentIndex - indexOffset;
          checkPreNext = false;
        } else {
          currentIndex--;
        }

        if (currentIndex < 0) {
          hasSectionsPre = false;
          continue;
        }

        if (percentageOnScreen(currentIndex, viewportHeight, scrollAxis) >
            0.8) {
          currentSectionIndex = currentIndex;
          return;
        }
      } else {
        if (hasSectionsPre) {
          currentIndex = currentIndex + indexOffset;
          checkPreNext = true;
        } else {
          currentIndex++;
        }

        if (currentIndex >= _sectionCount) {
          hasSectionsPost = false;
          continue;
        }

        if (percentageOnScreen(currentIndex, viewportHeight, scrollAxis) >
            0.8) {
          currentSectionIndex = currentIndex;
          return;
        }
      }
    }
    return;
  }

  // Calculates the percentage of the section that is visible on screen
  // Returns a value between 0.0 and 1.0 representing the percentage of that is visible on screen
  double percentageOnScreen(
    int sectionIndex,
    double viewportHeight,
    Axis scrollAxis,
  ) {
    final context =
        _sectionKeys[_currentItemIndex]?[sectionIndex]?.currentContext;

    final box = context?.findRenderObject() as RenderBox?;
    if (box == null) return 0.0;

    final sectionSize = scrollAxis == Axis.vertical
        ? box.size.height
        : box.size.width;

    final sectionFront = scrollAxis == Axis.vertical
        ? box.localToGlobal(Offset.zero).dy
        : box.localToGlobal(Offset.zero).dx;

    final sectionBack = scrollAxis == Axis.vertical
        ? box.localToGlobal(Offset.zero).dy + box.size.height
        : box.localToGlobal(Offset.zero).dx + box.size.width;

    double boundStart = scrollAxis == Axis.vertical ? 150 : 0;

    final sectionVisiblePercentage =
        ((sectionBack.clamp(boundStart, viewportHeight) -
                    sectionFront.clamp(boundStart, viewportHeight)) /
                sectionSize)
            .clamp(0.0, 1.0);

    return sectionVisiblePercentage;
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
