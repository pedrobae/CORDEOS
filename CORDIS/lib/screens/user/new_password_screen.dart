// ignore_for_file: unused_import, unused_field, unused_local_variable, prefer_final_fields

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:cordis/widgets/sheet_reauthenticate.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<MyAuthProvider, NavigationProvider>(
      builder: (context, authProvider, navProvider, child) {
        if (authProvider.error != null &&
            authProvider.error!.contains('requires-recent-login')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => ReAuthSheet(
                onReAuthSuccess: () {
                  Navigator.of(context).pop();
                  authProvider.updatePassword(_passwordController.text);
                },
              ),
            );
          });
        }

        return Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: BackButton(
                color: colorScheme.onSurface,
                onPressed: () => navProvider.attemptPop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  LabeledTextField(
                    label: AppLocalizations.of(
                      context,
                    )!.newPlaceholder(AppLocalizations.of(context)!.password),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  LabeledTextField(
                    label: AppLocalizations.of(context)!.confirmPassword,
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  if (authProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    ),
                  if (authProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  FilledTextButton(
                    text: AppLocalizations.of(context)!.save,
                    isDark: true,
                    onPressed: () {
                      if (_validate()) {
                        authProvider.updatePassword(_passwordController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
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
