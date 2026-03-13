import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/app_info_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/widgets/ciphers/editor/sections/sheet_new_section.dart';
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

class MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

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
  Widget build(BuildContext context) {
    final appInfo = context.read<AppInfoProvider>();
    return Consumer<NavigationProvider>(
      builder: (context, nav, child) {
        /// APP VERSION BLOCKER (used to disable alpha versions)
        final splitVersion = appInfo.appVersion.split('.');
        if (splitVersion[0] == '2') {
          return Scaffold(
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.appVersionNotSupported,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await nav.attemptPop(context);
          },
          child: Scaffold(
            appBar: nav.showAppBar ? _buildAppBar() : null,
            drawer: nav.showDrawerIcon ? SideMenu() : null,
            bottomNavigationBar: nav.showBottomNavBar
                ? _buildBottomNavigationBar(nav)
                : null,
            floatingActionButton: nav.showFAB ? _buildFAB(nav) : null,
            body: _buildBody(nav),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      centerTitle: true,
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
      onLongPress: () => _handleLongPressFAB(nav),
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

  void _handleLongPressFAB(NavigationProvider nav) {
    if (nav.currentRoute == NavigationRoute.library) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => NewSectionSheet(secret: true, versionId: -1),
      );
    }
  }

  void _handleFABTap(NavigationProvider nav) {
    switch (nav.currentRoute) {
      case NavigationRoute.library:
        _handleLibraryFAB(nav);
        break;
      case NavigationRoute.playlists:
        _handlePlaylistsFAB(nav);
        break;
      case NavigationRoute.home:
      case NavigationRoute.schedule:
        _showBottomSheetForCurrentRoute(nav.currentRoute);
        break;
    }
  }

  void _handleLibraryFAB(NavigationProvider nav) {
    final ciph = context.read<CipherProvider>();
    final sect = context.read<SectionProvider>();
    final localVer = context.read<LocalVersionProvider>();

    nav.push(
      () => EditCipherScreen(
        versionID: -1,
        cipherID: -1,
        versionType: VersionType.brandNew,
      ),
      changeDetector: () =>
          ciph.hasUnsavedChanges ||
          sect.hasUnsavedChanges ||
          localVer.hasUnsavedChanges,
      showBottomNavBar: true,
      onPopCallback: () => ciph.clearCipherFromCache(),
    );
  }

  void _handlePlaylistsFAB(NavigationProvider nav) {
    final localVer = context.read<LocalVersionProvider>();

    nav.push(
      () => EditPlaylistScreen(),
      changeDetector: () => localVer.hasUnsavedChanges,
      showBottomNavBar: true,
    );
  }

  void _showBottomSheetForCurrentRoute(NavigationRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        switch (route) {
          case NavigationRoute.home:
            return QuickActionSheet();
          case NavigationRoute.schedule:
            return ScheduleActionsSheet();
          case NavigationRoute.library:
          case NavigationRoute.playlists:
            throw Exception("These routes' FABs don't open a bottom sheet");
        }
      },
    );
  }
}
