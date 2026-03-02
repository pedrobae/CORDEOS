import 'dart:async';

import 'package:cordis/services/settings_service.dart';
import 'package:flutter/material.dart';

class AutoScrollProvider extends ChangeNotifier {
  AutoScrollProvider() {
    _loadSettings();
  }
  bool isAutoScrolling = false;
  double scrollSpeed = 1.0; // 0.5 = slow, 1 = normal, 1.5 = fast

  late final ValueNotifier<int> currentSectionIndex =
      ValueNotifier(0); // 0-based index of current section

  int get _totalSections => sectionKeys.length;

  Timer? autoScrollTimer;
  Timer? _updateTimer; // Separate timer for UI updates
  DateTime? _timerStartTime;
  // Returns a value between 0.0 and 1.0 representing progress to next section scroll
  double get timerProgress {
    if (autoScrollTimer == null || !autoScrollTimer!.isActive || _timerStartTime == null) {
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

  Map<int, GlobalKey> sectionKeys = {}; // Maps section index to its GlobalKey

  // ===== SETTINGS METHODS =====
  /// Gets settings from SettingsService and updates provider state
  Future<void> _loadSettings() async {
    currentSectionIndex.value = 0;
    isAutoScrolling = SettingsService.getAutoScrollEnabled();
    scrollSpeed = SettingsService.getAutoScrollSpeed();
    notifyListeners();
  }

  /// Updates scroll speed and saves to settings
  void setScrollSpeed(double value) {
    scrollSpeed = value;
    SettingsService.setAutoScrollSpeed(value);
    notifyListeners();
  }

  // ===== AUTO SCROLL METHODS =====
  /// Toggles auto-scroll on/off and starts/stops timer accordingly
  void toggleAutoScroll() {
    isAutoScrolling = !isAutoScrolling;
    if (isAutoScrolling) {
      startAutoScroll();
    } else {
      autoScrollTimer?.cancel();
      autoScrollTimer = null;
      _updateTimer?.cancel();
      _updateTimer = null;
      _timerStartTime = null;
    }
    SettingsService.setAutoScrollEnabled(isAutoScrolling);
    notifyListeners();
  }

  /// Starts the auto-scroll timer
  /// Which scrolls through sections at intervals based on scrollSpeed
  void startAutoScroll() {
    if (sectionKeys.isEmpty) return; // No sections available

    // Duration per section: 3 seconds at speed 1.0
    // Speed 0.5 = 6 seconds per section, Speed 1.5 = 2 seconds per section
    final durationPerSection = Duration(
      milliseconds: (3000 / scrollSpeed).toInt(),
    );

    // Scroll to first section immediately
    _timerStartTime = DateTime.now();
    scrollToSection(0);

    // Start update timer to refresh UI with new progress value (60fps)
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      notifyListeners();
    });

    autoScrollTimer = Timer.periodic(durationPerSection, (_) {
      if (sectionKeys.isEmpty) return;

      // Move to next section
      if (currentSectionIndex.value < _totalSections - 1) {
        currentSectionIndex.value++;
        scrollToSection(currentSectionIndex.value);
      } else {
        // Stop at the end
        autoScrollTimer?.cancel();
        autoScrollTimer = null;
        _updateTimer?.cancel();
        _updateTimer = null;
        _timerStartTime = null;
        isAutoScrolling = false;
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

  @override
  void dispose() {
    autoScrollTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}
