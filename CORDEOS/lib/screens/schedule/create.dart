import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/screens/playlist/playlist_library.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/create_edit/edit_details.dart';
import 'package:cordeos/widgets/schedule/create_edit/edit_roles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateScheduleScreen extends StatefulWidget {
  final int creationStep;

  const CreateScheduleScreen({super.key, required this.creationStep});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  late LocalScheduleProvider _scheduleProvider;

  @override
  void initState() {
    super.initState();
    _scheduleProvider = context.read<LocalScheduleProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleProvider.addListener(_scheduleErrorListener);
      }
    });
  }

  void _scheduleErrorListener() {
    if (!mounted) return;
    final error = _scheduleProvider.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scheduleProvider.removeListener(_scheduleErrorListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final localSch = Provider.of<LocalScheduleProvider>(context, listen: false);

    return Scaffold(
      appBar: _buildAppBar(nav),
      body: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(),
          _buildStepInstruction(),
          _buildStepSpacing(),
          _buildStepContent(),
          _buildContinueButton(localSch, nav, auth),
        ],
      ),
    );
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
      title: Text(
        AppLocalizations.of(context)!.schedulePlaylist,
        style: textTheme.titleMedium,
      ),
    );
  }

  Widget _buildStepIndicator() {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      AppLocalizations.of(context)!.stepXofY(widget.creationStep, 3),
      style: textTheme.titleLarge,
    );
  }

  Widget _buildStepInstruction() {
    final textTheme = Theme.of(context).textTheme;
    return switch (widget.creationStep) {
      1 => Text(
        AppLocalizations.of(context)!.selectPlaylistForScheduleInstruction,
        style: textTheme.bodyLarge,
      ),
      2 => Text(
        AppLocalizations.of(context)!.fillScheduleDetailsInstruction,
        style: textTheme.bodyLarge,
      ),
      3 => Text(
        AppLocalizations.of(context)!.createRolesAndAssignUsersInstruction,
        style: textTheme.bodyLarge,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildStepSpacing() {
    return switch (widget.creationStep) {
      1 => const SizedBox(height: 16),
      2 => const SizedBox.shrink(),
      3 => const SizedBox(height: 16),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildStepContent() {
    return switch (widget.creationStep) {
      1 => const Expanded(child: PlaylistLibraryScreen()),
      2 => Expanded(child: EditDetails(scheduleID: -1)),
      3 => const Expanded(child: EditRoles(scheduleId: -1)),
      _ => const SizedBox.shrink(),
    };
  }

  String _getButtonText() {
    return switch (widget.creationStep) {
      1 => AppLocalizations.of(context)!.keepGoing,
      2 => AppLocalizations.of(context)!.keepGoing,
      3 => AppLocalizations.of(
        context,
      )!.createPlaceholder(AppLocalizations.of(context)!.schedule),
      _ => 'ERROR',
    };
  }

  Widget _buildContinueButton(
    LocalScheduleProvider localSch,
    NavigationProvider nav,
    MyAuthProvider auth,
  ) {
    return Consumer<SelectionProvider>(
      builder: (context, sel, child) {
        return FilledTextButton(
          text: _getButtonText(),
          onPressed: () => _handleStepAction(localSch, nav, auth, sel),
          isDisabled: sel.selectedItemIds.length != 1,
          isDark: true,
        );
      },
    );
  }

  void _handleStepAction(
    LocalScheduleProvider localSch,
    NavigationProvider nav,
    MyAuthProvider auth,
    SelectionProvider sel,
  ) {
    switch (widget.creationStep) {
      case 1:
        localSch.cacheBrandNewSchedule(sel.selectedItemIds.first, auth.id!);
        nav.push(
          () => CreateScheduleScreen(creationStep: 2),
          showBottomNavBar: true,
        );
      case 2:
        nav.push(
          () => CreateScheduleScreen(creationStep: 3),
          showBottomNavBar: true,
        );

      case 3:
        localSch.createFromCache(auth.id!).then((success) {
          if (success && mounted) {
            sel.disableSelectionMode();
            nav.attemptPop(context, route: NavigationRoute.schedule);
          }
        });
      default:
        null;
    }
  }
}
