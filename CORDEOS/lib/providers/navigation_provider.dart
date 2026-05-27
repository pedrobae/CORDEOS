import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/screens/home_screen.dart';
import 'package:cordeos/screens/cipher/cipher_library.dart';
import 'package:cordeos/screens/playlist/playlist_library.dart';
import 'package:cordeos/screens/schedule/library.dart';
import 'package:cordeos/widgets/common/unsaved_changes_warning.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter/material.dart';

enum NavigationRoute { home, library, playlists, schedule }

/// Screen metadata for storing in the navigation stack
class _ScreenMetadata {
  final Widget Function() screenBuilder;
  Widget? screen; // Store the actual widget for keepAlive purposes
  final bool showAppBar;
  final bool showDrawerIcon;
  final bool showBottomNavBar;
  final bool showFAB;
  final bool handlesSystemBack;
  final bool keepAlive;
  final VoidCallback onPopCallback;
  final bool Function() changeDetector;
  final void Function() onChangeDiscarded;

  _ScreenMetadata({
    required this.screenBuilder,
    required this.showAppBar,
    required this.showDrawerIcon,
    required this.showBottomNavBar,
    required this.showFAB,
    required this.handlesSystemBack,
    required this.keepAlive,
    required this.onPopCallback,
    required this.changeDetector,
    required this.onChangeDiscarded,
  });

  Widget getScreenWidget() {
    return screen ??= screenBuilder();
  }
}

class NavigationProvider extends ChangeNotifier {
  NavigationRoute _currentRoute = NavigationRoute.home;

  // Store screen metadata instead of Widget instances to avoid build scope issues
  final List<_ScreenMetadata> _screenStack = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  NavigationRoute get currentRoute => _currentRoute;

  Widget buildCurrentScreen(BuildContext context) {
    List<Widget> mountedScreens = [];
    for (int i = 0; i < _screenStack.length; i++) {
      final screen = _screenStack[i];
      final isTop = i == _screenStack.length - 1;
      if (screen.keepAlive || isTop) {
        mountedScreens.add(
          Offstage(offstage: !isTop, child: screen.getScreenWidget()),
        );
      }
    }

    if (mountedScreens.isEmpty) {
      // If no screens are in the stack, show the current route's screen
      mountedScreens.add(_getScreenForRoute(_currentRoute));
    }

    return Stack(children: mountedScreens);
  }

  bool get showAppBar =>
      _screenStack.isNotEmpty ? _screenStack.last.showAppBar : true;
  bool get showDrawerIcon =>
      _screenStack.isNotEmpty ? _screenStack.last.showDrawerIcon : true;
  bool get showBottomNavBar =>
      _screenStack.isNotEmpty ? _screenStack.last.showBottomNavBar : true;
  bool get showFAB =>
      _screenStack.isNotEmpty ? _screenStack.last.showFAB : true;
  bool get shouldDeferSystemBack =>
      _screenStack.isNotEmpty && _screenStack.last.handlesSystemBack;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ///
  Future<void> attemptPop(
    BuildContext context, {
    NavigationRoute? route,
  }) async {
    debugPrint(
      'NAVIGATION - Attempting to pop. Stack length: ${_screenStack.length}',
    );
    final hasChanges =
        _screenStack.isNotEmpty && _screenStack.last.changeDetector();

    if (hasChanges) {
      // If the top of the pop interceptor stack is true, show the unsaved changes warning
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: UnsavedChangesWarning(
              onDiscard: () {
                Navigator.of(context).pop(); // Close the warning
                _screenStack.last.onChangeDiscarded();

                if (route != null) {
                  _navigateToRoute(route);
                } else {
                  pop();
                }
              },
              onCancel: () {
                Navigator.of(context).pop(); // Just close the warning
              },
            ),
          ),
        ),
      );
    } else {
      if (route != null) {
        _navigateToRoute(route);
      } else {
        pop();
      }
    }
  }

  /// USED BY THE MAIN SCREEN TO NAVIGATE BETWEEN CONTENT TABS
  // Navigation methods following your provider pattern
  void _navigateToRoute(NavigationRoute route) {
    debugPrint('NAVIGATION - Navigating to route: ${route.name}');
    _currentRoute = route;

    while (_screenStack.isNotEmpty) {
      pop();
    }

    _error = null; // Clear any previous errors
    notifyListeners();
  }

  void push(
    Widget Function() screenBuilder, {
    bool showAppBar = false,
    bool showDrawerIcon = false,
    bool showBottomNavBar = false,
    bool showFAB = false,
    bool handlesSystemBack = false,
    bool keepAlive = false,
    VoidCallback? onPopCallback,
    bool Function()? changeDetector,
    void Function()? onChangeDiscarded,
  }) {
    debugPrint('NAVIGATION - Pushing screen');
    _screenStack.add(
      _ScreenMetadata(
        screenBuilder: screenBuilder,
        showAppBar: showAppBar,
        showDrawerIcon: showDrawerIcon,
        showBottomNavBar: showBottomNavBar,
        showFAB: showFAB,
        handlesSystemBack: handlesSystemBack,
        keepAlive: keepAlive,
        onPopCallback: onPopCallback ?? () {},
        changeDetector: changeDetector ?? () => false,
        onChangeDiscarded: onChangeDiscarded ?? () {},
      ),
    );
    notifyListeners();
  }

  void pop() {
    debugPrint(
      'NAVIGATION - Popping screen. Stack length: ${_screenStack.length}',
    );
    if (_screenStack.isNotEmpty) {
      try {
        _screenStack.last.onPopCallback();
      } catch (e) {
        // Silently catch callback errors during pop to avoid deactivated widget issues
        debugPrint('Error in onPopCallback: $e');
      }
      _screenStack.removeLast();
      notifyListeners();
      return;
    }
    return;
  }

  /// Launch external URL using the default browser.
  /// Returns `true` when the URL was successfully handed off.
  Future<bool> launchURL(String rawUrl) async {
    final normalizedInput = rawUrl.trim();
    if (normalizedInput.isEmpty) {
      debugPrint('NAVIGATION - Empty URL, launch skipped');
      return false;
    }

    final uri = _normalizeExternalUri(normalizedInput);
    if (uri == null) {
      debugPrint('NAVIGATION - Invalid URL: $rawUrl');
      return false;
    }

    debugPrint('NAVIGATION - Launching URL: $uri');
    try {
      final didLaunch = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );

      if (!didLaunch) {
        debugPrint('NAVIGATION - URL launcher returned false: $uri');
      }

      return didLaunch;
    } catch (e) {
      debugPrint('NAVIGATION - Failed to launch URL ($uri): $e');
      return false;
    }
  }

  Uri? _normalizeExternalUri(String input) {
    final parsed = Uri.tryParse(input);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    // Support links entered without scheme, e.g. "example.com".
    return Uri.tryParse('https://$input');
  }

  // Error handling following your provider pattern
  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null; // Clear errors when starting to load
    }
    notifyListeners();
  }

  Widget _getScreenForRoute(NavigationRoute route) {
    switch (route) {
      case NavigationRoute.home:
        return HomeScreen();
      case NavigationRoute.library:
        return CipherLibraryScreen();
      case NavigationRoute.playlists:
        return PlaylistLibraryScreen();
      case NavigationRoute.schedule:
        return ScheduleLibraryScreen();
    }
  }

  NavigationItem getNavigationItem(
    BuildContext context,
    NavigationRoute route, {
    Color? color,
    Color? activeColor,
    double iconSize = 64,
  }) {
    return NavigationItem(
      route: route,
      title: _getTitleForRoute(context, route),
      icon: _getIconForRoute(route, iconColor: color, iconSize: iconSize),
      activeIcon: _getIconForRoute(
        route,
        iconColor: activeColor,
        iconSize: iconSize,
      ),
      index: route.index,
    );
  }

  String _getTitleForRoute(BuildContext context, NavigationRoute route) {
    switch (route) {
      case NavigationRoute.home:
        return AppLocalizations.of(context)!.home;
      case NavigationRoute.library:
        return AppLocalizations.of(context)!.library;
      case NavigationRoute.playlists:
        return AppLocalizations.of(context)!.playlists;
      case NavigationRoute.schedule:
        return AppLocalizations.of(context)!.schedule;
    }
  }

  Icon _getIconForRoute(
    NavigationRoute route, {
    Color? iconColor,
    double iconSize = 64,
  }) {
    switch (route) {
      case NavigationRoute.home:
        return Icon(Icons.home_outlined, color: iconColor, size: iconSize);
      case NavigationRoute.library:
        return Icon(
          Icons.library_music_outlined,
          color: iconColor,
          size: iconSize,
        );
      case NavigationRoute.playlists:
        return Icon(
          Icons.playlist_play_outlined,
          color: iconColor,
          size: iconSize,
        );
      case NavigationRoute.schedule:
        return Icon(
          Icons.calendar_month_outlined,
          color: iconColor,
          size: iconSize,
        );
    }
  }

  // Compose navigation lists as needed
  List<NavigationItem> getNavigationItems(
    BuildContext context, {
    Color? color,
    Color? activeColor,
    double iconSize = 64,
  }) {
    return [
      for (var route in NavigationRoute.values)
        getNavigationItem(
          context,
          route,
          color: color,
          activeColor: activeColor,
          iconSize: iconSize,
        ),
    ];
  }
}

// Helper class for navigation items
class NavigationItem {
  final NavigationRoute route;
  final String title;
  final Icon icon;
  final Icon activeIcon;
  final int index;

  NavigationItem({
    required this.route,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.index,
  });
}
