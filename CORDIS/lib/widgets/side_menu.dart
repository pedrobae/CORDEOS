import 'dart:math' as math;
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/screens/settings_screen.dart';
import 'package:cordis/screens/web_view_screen.dart';
import 'package:cordis/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer2<NavigationProvider, MyAuthProvider>(
      builder: (context, navigationProvider, authProvider, child) {
        return Drawer(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(),
          ),
          width: math.min(
            math.max(MediaQuery.of(context).size.width * (5 / 6), 300),
            400,
          ),
          backgroundColor: colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/logos/app_icon_transparent.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // MAIN NAVIGATION ITEMS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UserCard(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.surfaceContainerHighest,
                            width: 1.2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ListTile(
                        title: Text(AppLocalizations.of(context)!.about),
                        onTap: () {
                          /// WEBSITE WEBVIEW
                          Navigator.of(context).pop(); // Close the drawer first
                          navigationProvider.push(
                            const WebViewScreen(),
                            showBottomNavBar: true,
                            showAppBar: true,
                            showDrawerIcon: true,
                          );
                        },
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.surfaceContainerHighest,
                            width: 1.2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ListTile(
                        title: Text(AppLocalizations.of(context)!.settings),
                        onTap: () {
                          Navigator.of(context).pop();
                          navigationProvider.push(
                            const SettingsScreen(),
                            showBottomNavBar: true,
                            showAppBar: true,
                            showDrawerIcon: true,
                          );
                        },
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // LOGOUT BUTTON
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 20.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).pop();
                    authProvider.signOut();
                  },
                  child: Row(
                    spacing: 16,
                    children: [
                      Icon(Icons.logout),
                      Text(
                        AppLocalizations.of(context)!.logOut,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // FOOTER
              Container(
                decoration: BoxDecoration(color: Colors.grey[800]),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset(
                      'assets/logos/v2_simple_color_white.svg',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      AppLocalizations.of(context)!.newHeart,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.surface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
