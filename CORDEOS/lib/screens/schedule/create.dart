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
  late ValueNotifier<bool> _formValidNotifier;

  @override
  void initState() {
    super.initState();
    _scheduleProvider = context.read<LocalScheduleProvider>();

    _formValidNotifier = ValueNotifier(false);

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
    _formValidNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(),
          _buildStepInstruction(),
          SizedBox(height: 16),
          _buildStepContent(),
          _buildContinueButton(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final nav = context.read<NavigationProvider>();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        AppLocalizations.of(context)!.stepXofY(widget.creationStep, 3),
        style: textTheme.titleLarge,
      ),
    );
  }

  Widget _buildStepInstruction() {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: switch (widget.creationStep) {
        1 => Text(
          l10n.selectPlaylistForScheduleInstruction,
          style: textTheme.bodyLarge,
        ),
        2 => Text(
          l10n.fillScheduleDetailsInstruction,
          style: textTheme.bodyLarge,
        ),
        3 => Text(
          l10n.createRolesAndAssignUsersInstruction,
          style: textTheme.bodyLarge,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildStepContent() {
    return switch (widget.creationStep) {
      1 => const Expanded(child: PlaylistLibraryScreen()),
      2 => Expanded(
        child: EditDetails(
          scheduleID: -1,
          validFormNotifier: _formValidNotifier,
        ),
      ),
      3 => const Expanded(child: EditRoles(scheduleId: -1)),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildContinueButton() {
    final localSch = context.read<LocalScheduleProvider>();
    final nav = context.read<NavigationProvider>();

    final id = context.select<MyAuthProvider, String?>((auth) => auth.id);
    if (id == null) throw Exception('User ID is null in CreateScheduleScreen');

    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: switch (widget.creationStep) {
        1 => Selector<SelectionProvider, List<int>>(
          selector: (context, sel) => [...sel.selectedItemIds],
          builder: (context, selectedIds, child) {
            return FilledTextButton(
              text: l10n.keepGoing,
              isDark: true,
              isDisabled: selectedIds.length != 1,
              onPressed: () {
                localSch.cacheBrandNewSchedule(selectedIds.first, id);
                nav.push(
                  () => CreateScheduleScreen(creationStep: 2),
                  showBottomNavBar: true,
                );
              },
            );
          },
        ),
        2 => ValueListenableBuilder(
          valueListenable: _formValidNotifier,
          builder: (context, valid, child) {
            return FilledTextButton(
              text: l10n.keepGoing,
              isDark: true,
              isDisabled: !valid,
              onPressed: () {
                nav.push(
                  () => CreateScheduleScreen(creationStep: 3),
                  showBottomNavBar: true,
                );
              },
            );
          },
        ),
        3 => FilledTextButton(
          text: l10n.createPlaceholder(l10n.schedule),
          isDark: true,
          onPressed: () {
            localSch.createFromCache(id).then((success) {
              if (success && mounted) {
                context.read<SelectionProvider>().disableSelectionMode();
                nav.attemptPop(context, route: NavigationRoute.schedule);
              }
            });
          },
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
