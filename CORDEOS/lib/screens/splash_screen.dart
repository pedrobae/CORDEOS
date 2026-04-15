import 'package:cordeos/screens/main_screen.dart';
import 'package:cordeos/screens/user/login_screen.dart';
import 'package:cordeos/services/firebase/remote_config_service.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lottie_native/lottie_native.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;
  Future<bool>? _versionSupportFuture;
  bool _isPreloading = false;
  final DateTime _loadStartTime = DateTime.now();

  PageRoute<void> _buildSplashExitRoute(Widget destination) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  void _navigateToNextScreen(BuildContext context, bool isAuthenticated) {
    if (_hasNavigated) return;
    final ciph = context.read<CipherProvider>();
    final play = context.read<PlaylistProvider>();

    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (isAuthenticated) {
        // Eagerly load core data while the splash is still visible so the
        // first frame of MainScreen never blocks on SQLite reads.
        setState(() => _isPreloading = true);
        try {
          await ciph.loadCiphers();
          await play.loadPlaylists();
        } catch (_) {
          // Preload failures must not block navigation.
        }

        // Ensure splash is visible for at least 5 seconds to avoid jarring transitions
        final elapsed = DateTime.now().difference(_loadStartTime);
        if (elapsed < const Duration(seconds: 5)) {
          await Future.delayed(const Duration(seconds: 5) - elapsed);
        }
        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(_buildSplashExitRoute(const MainScreen()));
      } else {
        // Ensure splash is visible for at least 2.5 seconds to avoid jarring transitions
        final elapsed = DateTime.now().difference(_loadStartTime);
        if (elapsed < const Duration(milliseconds: 2500)) {
          await Future.delayed(const Duration(milliseconds: 2500) - elapsed);
        }
        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(_buildSplashExitRoute(const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, auth, child) {
        // Show splash screen while auth is initializing
        if (!auth.hasInitialized) {
          return _buildSplashScreen(context);
        }

        _versionSupportFuture ??=
            RemoteConfigService.isCurrentVersionSupported();

        return FutureBuilder<bool>(
          future: _versionSupportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _buildSplashScreen(context);
            }

            final isVersionSupported = snapshot.data ?? true;
            if (!isVersionSupported) {
              return _buildVersionBlockedScreen(context);
            }

            // Once initialized and supported, trigger navigation (only once)
            _navigateToNextScreen(context, auth.isAuthenticated);

            // Return splash while navigation is pending
            return _buildSplashScreen(context);
          },
        );
      },
    );
  }

  Scaffold _buildVersionBlockedScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update_alt_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                localizations.appVersionNotSupported,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildSplashScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: LottieView.fromAsset(
                filePath: 'assets/animations/iconLoad.json',
              ),
            ),
            const SizedBox(height: 32),
            if (_isPreloading) ...[
              const SizedBox(height: 16),
              Text(
                localizations.loading,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
