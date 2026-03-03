import 'dart:async';

import 'package:cordis/services/settings_service.dart';
import 'package:flutter/material.dart';

class AutoScrollProvider extends ChangeNotifier {
  AutoScrollProvider() {
    _loadSettings();
  }
  bool scrollModeEnabled = false;
  double scrollSpeed = 1.0; // 0.5 = slow, 1 = normal, 1.5 = fast

  bool isAutoScrolling = false;

  late final ValueNotifier<int> currentSectionIndex = ValueNotifier(
    0,
  ); // 0-based index of current section

  int get _totalSections => sectionKeys.length;

  Timer? autoScrollTimer;
  Timer? _updateTimer; // Separate timer for UI updates
  DateTime? _timerStartTime;

  Map<int, GlobalKey> sectionKeys = {}; // Maps section index to its GlobalKey

  // ===== SETTINGS METHODS =====
  /// Gets settings from SettingsService and updates provider state
  Future<void> _loadSettings() async {
    currentSectionIndex.value = 0;
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
    SettingsService.setAutoScrollEnabled(scrollModeEnabled);
    notifyListeners();
  }

  // ===== AUTO SCROLL METHODS =====
  /// Toggles auto-scroll on/off and starts/stops timer accordingly
  void toggleAutoScroll() {
    if (isAutoScrolling) {
      stopAutoScroll();
    } else {
      startAutoScroll();
    }
  }

  void stopAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _timerStartTime = null;
    isAutoScrolling = false;
    notifyListeners();
  }

  /// Starts the auto-scroll timer
  /// Which scrolls through sections at intervals based on scrollSpeed
  void startAutoScroll() {
    if (isAutoScrolling) return; // Already scrolling
    isAutoScrolling = true;
    notifyListeners();
    if (sectionKeys.isEmpty) return; // No sections available

    // Duration per section: 3 seconds at speed 1.0
    // Speed 0.5 = 6 seconds per section, Speed 1.5 = 2 seconds per section
    final durationPerSection = Duration(
      milliseconds: (3000 / scrollSpeed).toInt(),
    );

    // Scroll to first section immediately
    _timerStartTime = DateTime.now();

    // Start update timer to refresh UI with new progress value (60fps)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      notifyListeners();
    });

    autoScrollTimer = Timer.periodic(durationPerSection, (_) {
      if (sectionKeys.isEmpty) return;

      debugPrint(
        'Scrolling to ${currentSectionIndex.value + 1} / $_totalSections',
      );

      // Move to next section
      if (currentSectionIndex.value < _totalSections - 1) {
        currentSectionIndex.value++;
        scrollToSection(currentSectionIndex.value);
      } else {
        // Stop at the end
        stopAutoScroll();
      }
    });
  }

  /// Scrolls to the section at the given index using its GlobalKey
  void scrollToSection(int index) {
    if (index >= _totalSections) return;

    final sectionKey = sectionKeys[index];
    final context = sectionKey!.currentContext;

    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // Position section 20% from top
      );
    }

    currentSectionIndex.value = index;
  }

  // ===== HELPER METHODS =====
  /// Returns a value between 0.0 and 1.0 representing progress to next section scroll
  double get timerProgress {
    if (autoScrollTimer == null ||
        !autoScrollTimer!.isActive ||
        _timerStartTime == null) {
      return 0.0;
    }

    final durationPerSection = Duration(
      milliseconds: (3000 / scrollSpeed).toInt(),
    );

    // Calculate elapsed time since timer started
    final elapsed = DateTime.now().difference(_timerStartTime!);
    final elapsedMs = elapsed.inMilliseconds;

    // Return progress within current interval (0.0 to 1.0)
    return (elapsedMs % durationPerSection.inMilliseconds) /
        durationPerSection.inMilliseconds;
  }

  /// Calculates the current section index based on the scroll offset
  int calcCurrentIndex(double viewportHeight) {
    for (final entry in sectionKeys.entries) {
      final sectionContext = entry.value.currentContext;
      if (sectionContext == null) continue;

      final box = sectionContext.findRenderObject() as RenderBox?;
      if (box == null) continue;

      // Get section's position relative to the scrollable
      final sectionTop = box.localToGlobal(Offset.zero).dy;

      // Check if section is in viewport (accounting for some buffer)
      if (sectionTop > viewportHeight * 0.15 &&
          sectionTop < viewportHeight * 0.30) {
        return entry.key;
      }
    }
    return currentSectionIndex.value; // Fallback to current
  }

  /// Clears cache
  void clearCache() {
    sectionKeys.clear();
    currentSectionIndex.value = 0;
    _updateTimer?.cancel();
    _timerStartTime = null;
    autoScrollTimer?.cancel();
    autoScrollTimer = null;
    isAutoScrolling = false;
    notifyListeners();
  }

  // ===== CLEANUP =====
  @override
  void dispose() {
    autoScrollTimer?.cancel();
    currentSectionIndex.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }
}
