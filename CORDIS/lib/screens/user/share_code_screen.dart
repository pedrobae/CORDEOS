import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShareCodeScreen extends StatefulWidget {
  final void Function(BuildContext) onSuccess;
  final void Function(BuildContext) onBack;

  const ShareCodeScreen({
    super.key,
    required this.onSuccess,
    required this.onBack,
  });

  @override
  State<ShareCodeScreen> createState() => ShareCodeScreenState();
}

class ShareCodeScreenState extends State<ShareCodeScreen> {
  TextEditingController shareCodeController = TextEditingController();
  late MyAuthProvider _authProvider;
  late CloudScheduleProvider _cloudScheduleProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = context.read<MyAuthProvider>();
    _cloudScheduleProvider = context.read<CloudScheduleProvider>();
  }

  @override
  void dispose() {
    shareCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => widget.onBack(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 156.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(
              AppLocalizations.of(context)!.joinSchedule,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                AppLocalizations.of(context)!.shareCodeInstructions,
                textAlign: TextAlign.center,
              ),
            ),
            TextField(
              controller: shareCodeController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                ),
                hintText: AppLocalizations.of(context)!.enterShareCode,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.shadow,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_cloudScheduleProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_cloudScheduleProvider.error != null)
              Text(
                _cloudScheduleProvider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            FilledTextButton(
              text: _authProvider.isAuthenticated
                  ? AppLocalizations.of(context)!.keepGoing
                  : AppLocalizations.of(context)!.getStarted,
              isDark: true,
              onPressed: _joinViaShareCode,
            ),
          ],
        ),
      ),
    );
  }

  void _joinViaShareCode() async {
    final shareCode = shareCodeController.text.trim();

    if (shareCode.isEmpty) {
      // Show error if share code is empty
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.enterShareCode)),
        );
      }
      return;
    }

    try {
      final success = await _cloudScheduleProvider.joinScheduleWithCode(
        shareCode,
      );

      if (success) {
        if (mounted) {
          widget.onSuccess(context);
        }
      } else if (mounted) {
        // Show error if joining fails
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join schedule.')));
      }
    } catch (e) {
      // Show error if joining fails
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
