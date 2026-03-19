import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/screens/splash_screen.dart';
import 'package:cordis/services/remote_config_service.dart';
import 'package:cordis/widgets/ciphers/library/sheet_new_song.dart';
import 'package:cordis/widgets/home/quick_action_sheet.dart';
import 'package:cordis/widgets/schedule/library/sheet_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cordis/providers/navigation_provider.dart';

import 'package:cordis/widgets/side_menu.dart';

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
    return Consumer<NavigationProvider>(
      builder: (context, nav, child) {
        final isWideScreen = MediaQuery.of(context).size.width > 600;
        final showWideSidebar =
            isWideScreen && (nav.showDrawerIcon || nav.showBottomNavBar);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || nav.shouldDeferSystemBack) return;
            await nav.attemptPop(context);
          },
          child: Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            drawer: SideMenu(),
            body: Row(
              children: [
                if (showWideSidebar) _buildWideSidebar(nav),
                Expanded(child: _buildInnerScaffold(nav, isWideScreen)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInnerScaffold(NavigationProvider nav, bool isWideScreen) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: nav.showAppBar ? _buildAppBar(nav, isWideScreen) : null,
      bottomNavigationBar: !isWideScreen && nav.showBottomNavBar
          ? _buildBottomNavigationBar(nav)
          : null,
      floatingActionButton: nav.showFAB ? _buildFAB(nav) : null,
      body: _buildBody(nav),
    );
  }

  Widget _buildWideSidebar(NavigationProvider nav) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: nav.showBottomNavBar ? 96 : 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.surfaceContainerLowest,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu),
            ),
            Expanded(
              child: NavigationRail(
                selectedIndex: nav.currentRoute.index,
                labelType: NavigationRailLabelType.none,
                backgroundColor: Colors.transparent,
                indicatorColor: colorScheme.surfaceTint,
                indicatorShape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                
                onDestinationSelected: (index) {
                  if (mounted) {
                    nav.attemptPop(
                      context,
                      route: NavigationRoute.values[index],
                    );
                  }
                },
                destinations: nav
                    .getNavigationItems(
                      context,
                      iconSize: 28,
                      color: colorScheme.onSurface,
                      activeColor: colorScheme.primary,
                    )
                    .map(
                      (navItem) => NavigationRailDestination(
                        icon: navItem.icon,
                        padding: EdgeInsets.symmetric(vertical: 4),
                        selectedIcon: navItem.activeIcon,
                        label: Text(navItem.title),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(NavigationProvider nav, bool isWideScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: (nav.showDrawerIcon && !isWideScreen)
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      leadingWidth: nav.showDrawerIcon ? null : 0,
      title: Image.asset('assets/logos/app_icon_transparent.png', height: 40),
    );
  }

  Widget _buildBottomNavigationBar(NavigationProvider nav) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.surfaceContainerLowest,
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: nav.currentRoute.index,
        type: BottomNavigationBarType.shifting,
        selectedItemColor: colorScheme.primary,
        onTap: (index) {
          if (mounted) {
            nav.attemptPop(context, route: NavigationRoute.values[index]);
          }
        },
        items: nav
            .getNavigationItems(
              context,
              iconSize: 28,
              color: colorScheme.onSurface,
              activeColor: colorScheme.primary,
            )
            .map(
              (navItem) => BottomNavigationBarItem(
                icon: navItem.icon,
                label: navItem.title,
                backgroundColor: colorScheme.surface,
                activeIcon: navItem.activeIcon,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBody(NavigationProvider nav) {
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
            child: KeyedSubtree(
              key: ValueKey(nav.currentRoute),
              child: nav.buildCurrentScreen(context),
            ),
          );
        },
      ),
    );
  }

  GestureDetector _buildFAB(NavigationProvider nav) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _handleFABTap(nav),
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

  void _handleFABTap(NavigationProvider nav) {
    switch (nav.currentRoute) {
      case NavigationRoute.library:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => NewSongSheet(),
        );
        break;
      case NavigationRoute.playlists:
        final localVer = context.read<LocalVersionProvider>();
        nav.push(
          () => EditPlaylistScreen(),
          changeDetector: () => localVer.hasUnsavedChanges,
          showBottomNavBar: true,
        );
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
    }
  }
}
