// ignore_for_file: unused_import, unused_field, unused_local_variable, prefer_final_fields

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:cordeos/widgets/sheet_reauthenticate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewPasswordScreen extends StatefulWidget {
  final String? loginEmail;

  const NewPasswordScreen({super.key, this.loginEmail});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Consumer<MyAuthProvider>(
      builder: (context, auth, child) {
        _handleReauthIfNeeded(auth);
        return Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildHeader(nav), _buildContent(auth)],
        );
      },
    );
  }

  void _handleReauthIfNeeded(MyAuthProvider auth) {
    if (auth.error != null &&
        auth.error is FirebaseAuthException &&
        (auth.error as FirebaseAuthException).message!.contains(
          'requires-recent-login',
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => ReAuthSheet(
            onReAuthSuccess: () {
              Navigator.of(context).pop();
              auth.updatePassword(_passwordController.text);
            },
          ),
        );
      });
    }
  }

  Widget _buildHeader(NavigationProvider nav) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: BackButton(
        color: colorScheme.onSurface,
        onPressed: () => nav.attemptPop(context),
      ),
    );
  }

  Widget _buildContent(MyAuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          _buildPasswordField(),
          _buildConfirmPasswordField(),
          _buildStatusIndicators(auth),
          _buildSaveButton(auth),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return LabeledTextField(
      label: AppLocalizations.of(
        context,
      )!.newPlaceholder(AppLocalizations.of(context)!.password),
      controller: _passwordController,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return LabeledTextField(
      label: AppLocalizations.of(context)!.confirmPassword,
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
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
              auth.error!.message,
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

  Widget _buildSaveButton(MyAuthProvider auth) {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.save,
      isDark: true,
      onPressed: () {
        if (_validate()) {
          auth.updatePassword(_passwordController.text);
        }
      },
    );
  }

  bool _validate() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return false;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch),
        ),
      );
      return false;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordTooShort(6)),
        ),
      );
      return false;
    }
    return true;
  }
}
