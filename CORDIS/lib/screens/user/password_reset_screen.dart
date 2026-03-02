import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class PasswordResetScreen extends StatefulWidget {
  final String loginEmail;

  const PasswordResetScreen({super.key, required this.loginEmail});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.loginEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.passwordResetTitle),
      ),
      body: Consumer<MyAuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    AppLocalizations.of(context)!.passwordResetInstructions,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                LabeledTextField(
                  label: AppLocalizations.of(context)!.email,
                  controller: _emailController,
                ),
                FilledTextButton(
                  text: AppLocalizations.of(
                    context,
                  )!.sendPlaceholder(AppLocalizations.of(context)!.email),
                  isDark: true,
                  onPressed: () async {
                    await authProvider.sendPasswordResetEmail(
                      widget.loginEmail,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
