import 'dart:math' as math;
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/screens/admin/admin_screen.dart';
import 'package:cordeos/screens/settings/report_bug_screen.dart';
import 'package:cordeos/screens/settings/settings_screen.dart';
import 'package:cordeos/screens/user/login_screen.dart';
import 'package:cordeos/screens/about_screen.dart';
import 'package:cordeos/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nav = context.read<NavigationProvider>();
    final auth = context.read<MyAuthProvider>();

    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.horizontal()),
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
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/logos/app_icon_transparent_gray.png'
                      : 'assets/logos/app_icon_transparent.png',
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
            child: SingleChildScrollView(
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
                        nav.push(
                          () => const AboutScreen(),
                          showBottomNavBar: true,
                          showAppBar: true,
                          showDrawerIcon: true,
                          handlesSystemBack: true,
                        );
                      },
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
                      onLongPress: () {
                        /// SECRET SETTINGS
                        Navigator.of(context).pop();
                        nav.push(
                          () => const SettingsScreen(showSecrets: true),
                          showBottomNavBar: true,
                          showAppBar: true,
                          showDrawerIcon: true,
                        );
                      },
                      onTap: () {
                        Navigator.of(context).pop();
                        nav.push(
                          () => const SettingsScreen(),
                          showBottomNavBar: true,
                          showAppBar: true,
                          showDrawerIcon: true,
                        );
                      },
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ),
                  ),
                  if (auth.isAdmin)
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
                        title: Text(AppLocalizations.of(context)!.admin),
                        onTap: () {
                          Navigator.of(context).pop();
                          nav.push(
                            () => const AdminScreen(),
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                nav.push(
                  () => const ReportBugScreen(),
                  showAppBar: true,
                  showBottomNavBar: true,
                  showDrawerIcon: true,
                );
              },
              child: Row(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.feedback_outlined),
                  Text(
                    AppLocalizations.of(context)!.reportBug,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          // LOGOUT BUTTON
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await auth.signOut();
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: Row(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
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
                  'assets/logos/nh_colored_white.svg',
                  height: MediaQuery.of(context).size.height * 0.07,
                  fit: BoxFit.contain,
                ),
                Text(
                  AppLocalizations.of(context)!.newHeart,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
