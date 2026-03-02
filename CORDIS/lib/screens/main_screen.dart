import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/widgets/ciphers/editor/sections/sheet_new_section.dart';
import 'package:cordis/widgets/home/quick_action_sheet.dart';
import 'package:cordis/widgets/schedule/library/schedule_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';

import 'package:cordis/widgets/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late MyAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();

    _authProvider = context.read<MyAuthProvider>();
    _authProvider.addListener(_authListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _redirectIfNeeded();
    });
  }

  void _authListener() {
    _redirectIfNeeded();
  }

  void _redirectIfNeeded() {
    if (_authProvider.isAuthenticated) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer3<MyAuthProvider, NavigationProvider, CipherProvider>(
      builder:
          (context, authProvider, navigationProvider, cipherProvider, child) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                await navigationProvider.attemptPop(context);
              },
              child: Scaffold(
                appBar: navigationProvider.showAppBar
                    ? _buildAppBar(colorScheme)
                    : null,
                drawer: navigationProvider.showDrawerIcon
                    ? SideMenu() //
                    : null,
                bottomNavigationBar: navigationProvider.showBottomNavBar
                    ? _buildBottomNavigationBar(
                        colorScheme,
                        textTheme,
                        navigationProvider,
                      )
                    : null,
                floatingActionButton: navigationProvider.showFAB
                    ? _buildFAB(colorScheme, navigationProvider, cipherProvider)
                    : null,
                body: SafeArea(
                  child: Builder(
                    builder: (context) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
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
                          key: ValueKey(navigationProvider.currentRoute),
                          child: navigationProvider.buildCurrentScreen(context),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      centerTitle: true,
      title: Image.asset('assets/logos/app_icon_transparent.png', height: 40),
    );
  }

  Container _buildBottomNavigationBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
    NavigationProvider navProvider,
  ) {
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
        currentIndex: navProvider.currentRoute.index,
        type: BottomNavigationBarType.shifting,
        selectedItemColor: colorScheme.primary,
        onTap: (index) {
          if (mounted) {
            navProvider.attemptPop(
              context,
              route: NavigationRoute.values[index],
            );
          }
        },
        items: navProvider
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

  GestureDetector _buildFAB(
    ColorScheme colorScheme,
    NavigationProvider navProvider,
    CipherProvider cipherProvider,
  ) {
    return GestureDetector(
      onLongPress: () {
        if (navProvider.currentRoute == NavigationRoute.library) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return NewSectionSheet(secret: true);
            },
          );
        }
      },
      onTap: () {
        switch (navProvider.currentRoute) {
          case NavigationRoute.library:
            navProvider.push(
              EditCipherScreen(
                versionID: -1,
                cipherID: -1,
                versionType: VersionType.brandNew,
              ),
              changeDetector: () =>
                  cipherProvider.hasUnsavedChanges ||
                  context.read<SectionProvider>().hasUnsavedChanges ||
                  context.read<LocalVersionProvider>().hasUnsavedChanges,
              showBottomNavBar: true,
              onPopCallback: () => cipherProvider.clearNewCipherFromCache(),
            );
            break;
          case NavigationRoute.playlists:
            navProvider.push(
              EditPlaylistScreen(),
              changeDetector: () =>
                  context.read<LocalVersionProvider>().hasUnsavedChanges,
              showBottomNavBar: true,
            );
            break;
          case NavigationRoute.home:
          case NavigationRoute.schedule:
            _showBottomSheetForCurrentRoute(navProvider.currentRoute);
            break;
        }
      },
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
