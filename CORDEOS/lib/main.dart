import 'package:cordeos/providers/printing_provider.dart';
import 'package:cordeos/services/print_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/admin_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/user/email_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/cipher/import_provider.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/providers/settings/app_info_provider.dart';
import 'package:cordeos/providers/settings/settings_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/settings/secret_settings_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/play/play_state_provider.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/bug_report_provider.dart';
import 'package:cordeos/providers/cipher/edit_sections_state_provider.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';

import 'package:cordeos/services/firebase/firebase_service.dart';
import 'package:cordeos/services/firebase/remote_config_service.dart';
import 'package:cordeos/services/settings_service.dart';

import 'package:cordeos/screens/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized before database operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database
  tz.initializeTimeZones();

  await FirebaseService.initialize();
  await RemoteConfigService.initializeAndFetch();

  await SettingsService.initialize();
  await PrintCacheService.initialize();

  // Initialize date formatting for all locales
  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => LayoutSetProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => SecretSetProvider()..loadSettings(),
        ),
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
        // STATE PROVIDERS
        ChangeNotifierProvider(create: (_) => ScrollProvider()),
        ChangeNotifierProvider(create: (_) => PlayStateProvider()),
        ChangeNotifierProvider(create: (_) => EditSectionsStateProvider()),
        ChangeNotifierProvider(create: (_) => TokenProvider()),
        // FUNCTIONALITY PROVIDERS
        ChangeNotifierProvider(
          create: (_) => PrintingProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider(create: (_) => TranspositionProvider()),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
      ],
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
