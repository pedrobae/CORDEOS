import 'dart:io';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/routes/app_routes.dart';

import 'package:cordis/screens/user/password_reset_screen.dart';
import 'package:cordis/screens/user/register_screen.dart';
import 'package:cordis/screens/share_code_screen.dart';

import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';

import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MyAuthProvider>(
        builder: (context, auth, child) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 24,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                _buildHeader(),
                _buildEmailField(),
                _buildPasswordField(),
                _buildForgotPassword(),
                _buildStatusIndicators(auth),
                _buildActionButtons(auth),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/logos/app_icon_transparent.png',
          width: 150,
          height: 150,
        ),
        Text(
          AppLocalizations.of(context)!.signInTitle,
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    final colorScheme = Theme.of(context).colorScheme;
    return LabeledTextField(
      controller: _emailController,
      label: AppLocalizations.of(context)!.email,
      prefixIcon: Icon(Icons.email, color: colorScheme.shadow),
    );
  }

  Widget _buildPasswordField() {
    final colorScheme = Theme.of(context).colorScheme;
    return LabeledTextField(
      label: AppLocalizations.of(context)!.password,
      controller: _passwordController,
      obscureText: _obscurePassword,
      prefixIcon: Icon(Icons.lock, color: colorScheme.shadow),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: colorScheme.shadow,
        ),
        onPressed: _toggleObscure,
      ),
    );
  }

  Widget _buildForgotPassword() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 0,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return PasswordResetScreen(
                      loginEmail: _emailController.text,
                    );
                  },
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.forgotPassword,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(AppLocalizations.of(context)!.forgotPasswordSuffix),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators(MyAuthProvider auth) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 8,
      children: [
        if (auth.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          ),
        if (auth.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              auth.error!,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(MyAuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        FilledTextButton(
          text: AppLocalizations.of(context)!.login,
          isDark: true,
          isDisabled: auth.isLoading,
          onPressed: () => _emailSignIn(),
        ),
        if (!Platform.isIOS) _buildGoogleSignInButton(),
        _buildShareCodeButton(auth),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _googleSignIn(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FaIcon(
                FontAwesomeIcons.google,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 24,
                ),
                color: colorScheme.primary,
                child: Text(
                  AppLocalizations.of(context)!.signInWithPlaceholder('Google'),
                  style: textTheme.labelLarge!.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCodeButton(MyAuthProvider auth) {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.enterShareCode,
      onPressed: () async {
        await auth.signInAnonymously();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShareCodeScreen(
                onBack: (context) {
                  auth.signOut();
                  Navigator.of(context).pop();
                },
                onSuccess: (context) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                },
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSignUpLink() {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.accountCreationPrefix,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          ),
          child: Text(
            AppLocalizations.of(context)!.accountCreationSuffix,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _emailSignIn() async {
    final authProvider = context.read<MyAuthProvider>();
    final userProvider = context.read<UserProvider>();

    await authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (authProvider.isAuthenticated) {
      // Load users after successful login
      await userProvider.loadUsers();
      await userProvider.ensureUserExists(authProvider.id!);

      authProvider.setUserData(
        userProvider.getUserByFirebaseId(authProvider.id!)!,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    }
  }

  void _googleSignIn() async {
    final authProvider = context.read<MyAuthProvider>();
    final userProvider = context.read<UserProvider>();

    await authProvider.signInWithGoogle();
    if (authProvider.isAuthenticated) {
      // Load users after successful login
      await userProvider.loadUsers();
      await userProvider.ensureUserExists(authProvider.id!);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
      authProvider.setUserData(
        userProvider.getUserByFirebaseId(authProvider.id!)!,
      );
    }
  }
}
