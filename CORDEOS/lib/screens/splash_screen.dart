import 'package:cordeos/screens/main_screen.dart';
import 'package:cordeos/screens/user/login_screen.dart';
import 'package:cordeos/services/firebase/remote_config_service.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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

  void _navigateToNextScreen(BuildContext context, bool isAuthenticated) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (isAuthenticated) {
        // Eagerly load core data while the splash is still visible so the
        // first frame of MainScreen never blocks on SQLite reads.
        setState(() => _isPreloading = true);
        try {
          await context.read<CipherProvider>().loadCiphers();
          await context.read<PlaylistProvider>().loadPlaylists();
        } catch (_) {
          // Preload failures must not block navigation.
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
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

        _versionSupportFuture ??= RemoteConfigService.isCurrentVersionSupported();

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
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildSplashScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/app_icon_transparent.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: colorScheme.primary),
            if (_isPreloading) ...[
              const SizedBox(height: 16),
              Text(
                localizations.loading,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
