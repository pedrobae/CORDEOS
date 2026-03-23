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
  late CloudScheduleProvider _cloudSch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = context.read<MyAuthProvider>();
    _cloudSch = context.read<CloudScheduleProvider>();
  }

  @override
  void dispose() {
    shareCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<CloudScheduleProvider>(
        builder: (context, cloudSch, child) {
          if (cloudSch.isLoading) {
            return _buildLoadingState();
          }
          if (cloudSch.error != null) {
            return _buildErrorState(cloudSch);
          }
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 156.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                _buildHeader(),
                _buildShareCodeInput(),
                const SizedBox(height: 8),
                _buildJoinButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(leading: BackButton(onPressed: () => widget.onBack(context)));
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(CloudScheduleProvider cloudSch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cloudSch.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          FilledTextButton(
            text: AppLocalizations.of(context)!.tryAgain,
            onPressed: () => cloudSch.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ],
    );
  }

  Widget _buildShareCodeInput() {
    return TextField(
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
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.shadow),
      ),
    );
  }

  Widget _buildJoinButton() {
    return FilledTextButton(
      text: _authProvider.isAuthenticated
          ? AppLocalizations.of(context)!.keepGoing
          : AppLocalizations.of(context)!.getStarted,
      isDark: true,
      onPressed: _joinViaShareCode,
    );
  }

  void _joinViaShareCode() async {
    final shareCode = shareCodeController.text.trim();

    if (shareCode.isEmpty) {
      // Show message if share code is empty
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.enterShareCode)),
        );
      }
      return;
    }

    final success = await _cloudSch.joinScheduleWithCode(
      shareCode,
    );

    if (mounted) {
      if (success) {
        widget.onSuccess(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.joinedScheduleSuccessfully,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _cloudSch.error!,
            ),
          ),
        );
      }
    }
  }
}
