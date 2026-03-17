import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/bug_report_provider.dart';
import 'package:cordis/providers/settings/secret_settings_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/screens/splash_screen.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:provider/provider.dart';
import 'package:cordis/providers/user/admin_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/user/email_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/cipher/import_provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/cipher/parser_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/settings/settings_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/app_info_provider.dart';
import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';

import 'package:cordis/services/firebase_service.dart';
import 'package:cordis/services/remote_config_service.dart';
import 'package:cordis/services/settings_service.dart';

void main() async {
  // Ensure Flutter is initialized before database operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database
  tz.initializeTimeZones();

  await FirebaseService.initialize();
  await RemoteConfigService.initializeAndFetch();

  await SettingsService.initialize();

  // Initialize date formatting for all locales
  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final providers = [
    //  APP-WIDE PROVIDERS
    ChangeNotifierProvider(create: (_) => MyAuthProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
    ChangeNotifierProvider(create: (_) => LayoutSetProvider()..loadSettings()),
    ChangeNotifierProvider(create: (_) => SecretSetProvider()..loadSettings()),
    ChangeNotifierProvider(create: (_) => AppInfoProvider()..initialize()),
    ChangeNotifierProvider(create: (_) => BugReportProvider()),
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
    // ADMIN DOMAIN PROVIDERS
    ChangeNotifierProvider(create: (_) => AdminProvider()),
    // LOCAL DOMAIN PROVIDERS
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => CipherProvider()),
    ChangeNotifierProvider(create: (_) => LocalVersionProvider()),
    ChangeNotifierProvider(create: (_) => SectionProvider()),
    ChangeNotifierProvider(create: (_) => PlaylistProvider()),
    ChangeNotifierProvider(create: (_) => FlowItemProvider()),
    ChangeNotifierProvider(create: (_) => LocalScheduleProvider()),
    // CLOUD DOMAIN PROVIDERS
    ChangeNotifierProvider(create: (_) => CloudScheduleProvider()),
    ChangeNotifierProvider(create: (_) => CloudVersionProvider()),
    // IMPORT PROVIDERS
    ChangeNotifierProvider(create: (_) => ImportProvider()),
    ChangeNotifierProvider(create: (_) => ParserProvider()),
    // PLAY SCHEDULE PROVIDERS
    ChangeNotifierProvider(create: (_) => AutoScrollProvider()),
    ChangeNotifierProvider(create: (_) => PlayScheduleStateProvider()),
    // FUNCTIONALITY PROVIDERS
    ChangeNotifierProvider(create: (_) => SelectionProvider()),
    ChangeNotifierProvider(create: (_) => TranspositionProvider()),
    ChangeNotifierProvider(create: (_) => EmailProvider()),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', ''), Locale('pt', 'BR')],
            locale: settingsProvider.locale,
            title: AppLocalizations.of(context)?.appName,
            theme: settingsProvider.lightTheme,
            darkTheme: settingsProvider.darkTheme,
            themeMode: settingsProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
