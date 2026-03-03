import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/playlist/playlist_library.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/details_form.dart';
import 'package:cordis/widgets/schedule/create_edit/roles_users_form.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roomVenueController = TextEditingController();
  final TextEditingController _annotationsController = TextEditingController();

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

    // Dispose all controllers
    _nameController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _locationController.dispose();
    _roomVenueController.dispose();
    _annotationsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final sel = Provider.of<SelectionProvider>(context, listen: false);
    final localSch = Provider.of<LocalScheduleProvider>(context, listen: false);

    return Scaffold(
      appBar: _buildAppBar(nav),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            _buildStepInstruction(),
            _buildStepSpacing(),
            _buildStepContent(),
            _buildContinueButton(localSch, nav, auth, sel),
          ],
        ),
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
      2 => Expanded(
        child: ScheduleForm(
          scheduleId: -1,
          nameController: _nameController,
          dateController: _dateController,
          startTimeController: _startTimeController,
          locationController: _locationController,
          roomVenueController: _roomVenueController,
          annotationsController: _annotationsController,
        ),
      ),
      3 => const Expanded(child: RolesAndUsersForm(scheduleId: -1)),
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
    SelectionProvider sel,
  ) {
    return FilledTextButton(
      text: _getButtonText(),
      onPressed: () => _handleStepAction(localSch, nav, auth, sel),
      isDisabled: sel.selectedItemIds.length != 1,
      isDark: true,
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
        _handleStep1(localSch, nav, auth, sel);
      case 2:
        _handleStep2(localSch, nav);
      case 3:
        _handleStep3(localSch, nav, auth);
      default:
        null;
    }
  }

  void _handleStep1(
    LocalScheduleProvider localSch,
    NavigationProvider nav,
    MyAuthProvider auth,
    SelectionProvider sel,
  ) {
    localSch.cacheBrandNewSchedule(sel.selectedItemIds.first, auth.id!);
    nav.push(CreateScheduleScreen(creationStep: 2), showBottomNavBar: true);
  }

  void _handleStep2(LocalScheduleProvider localSch, NavigationProvider nav) {
    localSch.cacheScheduleDetails(
      -1,
      name: _nameController.text,
      date: _dateController.text,
      startTime: _startTimeController.text,
      location: _locationController.text,
      roomVenue: _roomVenueController.text,
      annotations: _annotationsController.text,
    );
    nav.push(CreateScheduleScreen(creationStep: 3), showBottomNavBar: true);
  }

  void _handleStep3(
    LocalScheduleProvider localSch,
    NavigationProvider nav,
    MyAuthProvider auth,
  ) {
    localSch.createFromCache(auth.id!).then((success) {
      if (success && mounted) {
        nav.attemptPop(context, route: NavigationRoute.schedule);
      }
    });
  }
}
