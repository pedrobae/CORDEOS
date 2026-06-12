import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/screens/playlist/edit_playlist.dart';
import 'package:cordeos/screens/splash_screen.dart';
import 'package:cordeos/services/firebase/remote_config_service.dart';
import 'package:cordeos/widgets/ciphers/library/sheet_new_song.dart';
import 'package:cordeos/widgets/home/quick_action_sheet.dart';
import 'package:cordeos/widgets/schedule/library/sheet_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cordeos/providers/navigation_provider.dart';

import 'package:cordeos/widgets/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _versionGateTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _runVersionGate();
      if (!mounted || _versionGateTriggered) return;

      // Load users
      final user = context.read<UserProvider>();
      final auth = context.read<MyAuthProvider>();

      await user.ensureUserExists(auth.id!);
      await user.loadUsers();

      final currentUser = user.getUserByFirebaseId(auth.id!);

      if (currentUser == null) {
        throw Exception(
          "Current user should not be null after ensuring existence and loading users",
        );
      }

      auth.setUserData(currentUser);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runVersionGate();
    }
  }

  Future<void> _runVersionGate() async {
    if (_versionGateTriggered) {
      return;
    }

    await RemoteConfigService.initializeAndFetch();
    final isSupported = await RemoteConfigService.isCurrentVersionSupported();

    if (!mounted || isSupported || _versionGateTriggered) {
      return;
    }

    _versionGateTriggered = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<
      NavigationProvider,
      ({bool showSidebar, bool shouldDeferSystemBack, bool isWide})
    >(
      selector: (context, nav) {
        final isWide = MediaQuery.of(context).size.width > 600;
        return (
          isWide: isWide,
          shouldDeferSystemBack: nav.shouldDeferSystemBack,
          showSidebar: isWide && (nav.showDrawerIcon || nav.showBottomNavBar),
        );
      },
      builder: (context, s, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || s.shouldDeferSystemBack) return;
            final nav = context.read<NavigationProvider>();
            await nav.attemptPop(context);
          },
          child: Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            drawer: SideMenu(),
            drawerEnableOpenDragGesture: false,
            body: Row(
              children: [
                if (s.showSidebar) _buildSidebar(),
                Expanded(child: _buildInnerScaffold(s.isWide)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInnerScaffold(bool isWideScreen) {
    return Selector<
      NavigationProvider,
      ({bool showAppbar, bool showNav, bool showDrawerIcon, bool showFAB})
    >(
      selector: (context, nav) => (
        showAppbar: nav.showAppBar,
        showFAB: nav.showFAB,
        showDrawerIcon: nav.showDrawerIcon,
        showNav: !isWideScreen && nav.showBottomNavBar,
      ),
      builder: (context, s, child) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: s.showAppbar
            ? _buildAppBar(isWideScreen, s.showDrawerIcon)
            : null,
        bottomNavigationBar: s.showNav ? _buildBottomNavigationBar() : null,
        floatingActionButton: s.showFAB ? _buildFAB() : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildSidebar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.shadow, width: 0.5),
        ),
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: Column(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu),
            ),
            Expanded(
              child:
                  Selector<
                    NavigationProvider,
                    ({int? selectedIndex, List<NavigationItem> items})
                  >(
                    selector: (context, nav) {
                      return (
                        selectedIndex: nav.currentRoute?.index,
                        items: nav.getNavigationItems(
                          context,
                          iconSize: 28,
                          color: colorScheme.onSurface,
                          activeColor: colorScheme.primary,
                        ),
                      );
                    },
                    builder: (context, s, child) {
                      return NavigationRail(
                        selectedIndex: s.selectedIndex,
                        labelType: NavigationRailLabelType.none,
                        backgroundColor: Colors.transparent,
                        indicatorColor: colorScheme.surfaceTint,
                        indicatorShape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        onDestinationSelected: (index) {
                          final nav = context.read<NavigationProvider>();
                          if (mounted) {
                            nav.attemptPop(
                              context,
                              route: NavigationRoute.values[index],
                            );
                          }
                        },
                        destinations: s.items
                            .map(
                              (navItem) => NavigationRailDestination(
                                icon: navItem.icon,
                                padding: EdgeInsets.symmetric(vertical: 4),
                                selectedIcon: navItem.activeIcon,
                                label: Text(navItem.title),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isWideScreen, bool showDrawerIcon) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: (showDrawerIcon && !isWideScreen)
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      leadingWidth: showDrawerIcon ? null : 0,
      title: Image.asset(
        Theme.of(context).brightness == Brightness.dark
            ? 'assets/logos/app_icon_transparent_gray.png'
            : 'assets/logos/app_icon_transparent.png',
        height: 40,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.shadow)),
      ),
      child:
          Selector<
            NavigationProvider,
            ({int? selectedIndex, List<NavigationItem> items})
          >(
            selector: (context, nav) {
              return (
                selectedIndex: nav.currentRoute?.index,
                items: nav.getNavigationItems(
                  context,
                  iconSize: 28,
                  color: colorScheme.onSurface,
                  activeColor: colorScheme.primary,
                ),
              );
            },
            builder: (context, s, child) {
              return s.selectedIndex != null
                  ? BottomNavigationBar(
                      currentIndex: s.selectedIndex!,
                      type: BottomNavigationBarType.shifting,
                      selectedItemColor: colorScheme.primary,
                      onTap: (index) {
                        final nav = context.read<NavigationProvider>();
                        if (mounted) {
                          nav.attemptPop(
                            context,
                            route: NavigationRoute.values[index],
                          );
                        }
                      },
                      items: s.items
                          .map(
                            (navItem) => BottomNavigationBarItem(
                              icon: navItem.icon,
                              label: navItem.title,
                              backgroundColor: colorScheme.surface,
                              activeIcon: navItem.activeIcon,
                            ),
                          )
                          .toList(),
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ...s.items.map(
                            (navItem) => SizedBox(
                              height: 62,
                              child: IconButton(
                                icon: navItem.icon,
                                color: colorScheme.surface,
                                onPressed: () {
                                  final nav = context
                                      .read<NavigationProvider>();
                                  nav.attemptPop(context, route: navItem.route);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
            },
          ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Builder(
        builder: (context) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                children: <Widget>[
                  ...previousChildren,
                  currentChild ?? const SizedBox.shrink(),
                ],
              );
            },
            child:
                Selector<
                  NavigationProvider,
                  ({Widget currentScreen, NavigationRoute? currentRoute})
                >(
                  selector: (context, nav) => (
                    currentScreen: nav.buildCurrentScreen(context),
                    currentRoute: nav.currentRoute,
                  ),
                  builder: (context, s, child) {
                    return KeyedSubtree(
                      key: ValueKey(s.currentRoute),
                      child: s.currentScreen,
                    );
                  },
                ),
          );
        },
      ),
    );
  }

  GestureDetector _buildFAB() {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _handleFABTap(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.onSurface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.surfaceContainerLowest,
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(Icons.add, color: colorScheme.surface),
      ),
    );
  }

  void _handleFABTap() {
    final nav = context.read<NavigationProvider>();

    switch (nav.currentRoute) {
      case NavigationRoute.library:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => NewSongSheet(),
        );
        break;
      case NavigationRoute.playlists:
        nav.push(() => EditPlaylistScreen(), showBottomNavBar: true);
        break;
      case NavigationRoute.home:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return QuickActionSheet();
          },
        );
        break;
      case NavigationRoute.schedule:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return ScheduleActionsSheet();
          },
        );
        break;
      case _:
        break;
    }
  }
}
