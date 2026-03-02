import 'dart:math';

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A bottom sheet that is called when the user needs to re-authenticate,
/// Before performing sensitive actions like changing password.
class ReAuthSheet extends StatefulWidget {
  final VoidCallback onReAuthSuccess;

  const ReAuthSheet({super.key, required this.onReAuthSuccess});

  @override
  State<ReAuthSheet> createState() => _ReAuthSheetState();
}

class _ReAuthSheetState extends State<ReAuthSheet> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<MyAuthProvider>();
      emailController.text = authProvider.userEmail ?? '';
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          child: Container(
            color: colorScheme.surface,
            padding: EdgeInsets.only(
              left: 16.0,
              top: 16.0,
              right: 16.0,
              bottom: max(16.0, MediaQuery.of(context).viewInsets.bottom),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.reauthenticationRequired,
                      style: textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.email,
                  controller: emailController,
                ),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.password,
                  controller: passwordController,
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                FilledTextButton(
                  text: AppLocalizations.of(context)!.keepGoing,
                  isDark: true,
                  onPressed: () {
                    authProvider.reauthenticate(
                      emailController.text,
                      passwordController.text,
                    );
                    Navigator.of(context).pop();
                    widget.onReAuthSuccess();
                  },
                ),
                SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }
}
