import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/screens/home_screen.dart';
import 'package:cordis/screens/cipher/cipher_library.dart';
import 'package:cordis/screens/playlist/playlist_library.dart';
import 'package:cordis/screens/schedule/library.dart';
import 'package:cordis/widgets/common/unsaved_changes_warning.dart';
import 'package:flutter/material.dart';

enum NavigationRoute { home, library, playlists, schedule }

/// Screen metadata for storing in the navigation stack
class _ScreenMetadata {
  final Widget Function() screenBuilder;
  final bool showAppBar;
  final bool showDrawerIcon;
  final bool showBottomNavBar;
  final bool showFAB;
  final bool handlesSystemBack;
  final VoidCallback onPopCallback;
  final bool Function() changeDetector;

  _ScreenMetadata({
    required this.screenBuilder,
    required this.showAppBar,
    required this.showDrawerIcon,
    required this.showBottomNavBar,
    required this.showFAB,
    required this.handlesSystemBack,
    required this.onPopCallback,
    required this.changeDetector,
  });
}

class NavigationProvider extends ChangeNotifier {
  NavigationRoute _currentRoute = NavigationRoute.home;

  // Store screen metadata instead of Widget instances to avoid build scope issues
  final List<_ScreenMetadata> _screenStack = [];

  Widget?
  _screenOnForeground; // Screen that can be placed on top of the current stack without affecting it

  bool _isLoading = false;
  String? _error;

  // Getters
  NavigationRoute get currentRoute => _currentRoute;

  Widget buildCurrentScreen(BuildContext context) {
    // Build the current screen from metadata to ensure proper build context
    final currentScreenWidget = _screenStack.isNotEmpty
        ? _screenStack.last.screenBuilder()
        : _getScreenForRoute(_currentRoute);

    return Stack(
      children: [
        currentScreenWidget,
        if (_screenOnForeground != null)
          Positioned.fill(
            child: _screenOnForeground!,
          ),
      ],
    );
  }

  Widget? get screenOnForeground => _screenOnForeground;
  bool get showAppBar =>
      _screenStack.isNotEmpty ? _screenStack.last.showAppBar : true;
  bool get showDrawerIcon =>
      _screenStack.isNotEmpty ? _screenStack.last.showDrawerIcon : true;
  bool get showBottomNavBar =>
      _screenStack.isNotEmpty ? _screenStack.last.showBottomNavBar : true;
  bool get showFAB => _screenStack.isNotEmpty ? _screenStack.last.showFAB : true;
    bool get shouldDeferSystemBack =>
      _screenStack.isNotEmpty && _screenStack.last.handlesSystemBack;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ///
  Future<void> attemptPop(
    BuildContext context, {
    NavigationRoute? route,
  }) async {
    final hasChanges = _screenStack.isNotEmpty && 
                       _screenStack.last.changeDetector();
    
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
    _screenOnForeground =
        null; // Clear any foreground screen when navigating to a new route
    _screenStack.clear();

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
    VoidCallback? onPopCallback,
    bool Function()? changeDetector,
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
        onPopCallback: onPopCallback ?? () {},
        changeDetector: changeDetector ?? () => false,
      ),
    );
    notifyListeners();
  }

  void pushForeground(Widget screen) {
    debugPrint('NAVIGATION - Pushing foreground screen: ${screen.runtimeType}');

    _screenOnForeground = screen;
    notifyListeners();
  }

  void pushReplacement(
    Widget Function() screenBuilder, {
    bool showAppBar = false,
    bool showDrawerIcon = false,
    bool showBottomNavBar = false,
    bool showFAB = false,
    bool handlesSystemBack = false,
    VoidCallback? onPopCallback,
    bool Function()? changeDetector,
  }) {
    if (_screenStack.isNotEmpty) {
      pop();
    }
    push(
      screenBuilder,
      showAppBar: showAppBar,
      showDrawerIcon: showDrawerIcon,
      showBottomNavBar: showBottomNavBar,
      showFAB: showFAB,
      handlesSystemBack: handlesSystemBack,
      onPopCallback: onPopCallback,
      changeDetector: changeDetector,
    );
  }

  void pop() {
    if (_screenOnForeground != null) {
      _screenOnForeground = null;
      notifyListeners();
      return;
    }
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
