import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/playlist/playlist_library.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/details_form.dart';
import 'package:cordis/widgets/schedule/create_edit/roles_users_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum EditScheduleMode { details, playlist, roleMember }

class EditScheduleScreen extends StatefulWidget {
  final EditScheduleMode mode;
  final int scheduleId;

  const EditScheduleScreen({
    super.key,
    required this.mode,
    required this.scheduleId,
  });

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController roomVenueController = TextEditingController();
  final TextEditingController annotationsController = TextEditingController();

  late LocalScheduleProvider _scheduleProvider;

  @override
  void initState() {
    super.initState();
    _scheduleProvider = context.read<LocalScheduleProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleProvider.addListener(_scheduleErrorListener);
        final schedule = _scheduleProvider.getSchedule(widget.scheduleId);
        _populateControllers(schedule);
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

    nameController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    locationController.dispose();
    annotationsController.dispose();

    super.dispose();
  }

  void _populateControllers(dynamic schedule) {
    if (schedule == null) throw Exception('Schedule not found');

    nameController.text = schedule?.name ?? '';
    dateController.text = (schedule is Schedule)
        ? DateTimeUtils.formatDate(schedule.date)
        : schedule.datetime.toDate().toIso8601String();
    startTimeController.text = (schedule is Schedule)
        ? '${schedule.time.hour.toString().padLeft(2, '0')}:${schedule.time.minute.toString().padLeft(2, '0')}'
        : '${schedule.datetime.toDate().hour.toString().padLeft(2, '0')}:${ //
          schedule.datetime.toDate().minute.toString().padLeft(2, '0')}';
    locationController.text = schedule?.location ?? '';
    roomVenueController.text = schedule?.roomVenue ?? '';
    annotationsController.text = schedule?.annotations ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold(
      appBar: _buildAppBar(nav),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildModeContent(), _buildActionButtons(context, nav)],
        ),
      ),
    );
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
      title: Text(
        AppLocalizations.of(
          context,
        )!.editPlaceholder(AppLocalizations.of(context)!.scheduleDetails),
        style: textTheme.titleMedium,
      ),
    );
  }

  Widget _buildModeContent() {
    return Expanded(
      child: switch (widget.mode) {
        EditScheduleMode.details => ScheduleForm(
          nameController: nameController,
          dateController: dateController,
          startTimeController: startTimeController,
          locationController: locationController,
          roomVenueController: roomVenueController,
        ),
        EditScheduleMode.playlist => const PlaylistLibraryScreen(),
        EditScheduleMode.roleMember => RolesAndUsersForm(
          scheduleId: widget.scheduleId,
        ),
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, NavigationProvider nav) {
    final sel = Provider.of<SelectionProvider>(context, listen: false);

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledTextButton(
          text: AppLocalizations.of(context)!.save,
          onPressed: () => _handleSave(context, nav, sel),
          isDisabled: sel.isSelectionMode && sel.selectedItemIds.length != 1,
          isDark: true,
        ),
        FilledTextButton(
          text: AppLocalizations.of(context)!.cancel,
          onPressed: () => nav.attemptPop(context),
        ),
      ],
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    NavigationProvider nav,
    SelectionProvider sel,
  ) async {
    final auth = Provider.of<MyAuthProvider>(context, listen: false);
    final localSch = Provider.of<LocalScheduleProvider>(context, listen: false);
    final play = Provider.of<PlaylistProvider>(context, listen: false);

    switch (widget.mode) {
      case EditScheduleMode.details:
        await _saveDetails(localSch);
      case EditScheduleMode.playlist:
        await _savePlaylist(localSch, play, sel);
      case EditScheduleMode.roleMember:
        await _saveRoleMember(localSch);
    }

    if (localSch.isLive(widget.scheduleId)) {
      localSch.uploadScheduleToCloud(widget.scheduleId, auth.id!);
    }

    nav.pop();
  }

  Future<void> _saveDetails(LocalScheduleProvider localSch) async {
    localSch.cacheScheduleDetails(
      widget.scheduleId,
      name: nameController.text,
      date: dateController.text,
      startTime: startTimeController.text,
      location: locationController.text,
      roomVenue: roomVenueController.text,
      annotations: annotationsController.text,
    );
    await localSch.saveSchedule(widget.scheduleId);
  }

  Future<void> _savePlaylist(
    LocalScheduleProvider localSch,
    PlaylistProvider play,
    SelectionProvider sel,
  ) async {
    if (sel.selectedItemIds.isEmpty) return;

    final selectedPlaylistId = sel.selectedItemIds.first as int;
    final selectedPlaylist = play.getPlaylistById(selectedPlaylistId);
    if (selectedPlaylist == null) return;

    localSch.assignPlaylistToSchedule(widget.scheduleId, selectedPlaylistId);

    await localSch.saveSchedule(widget.scheduleId);
  }

  Future<void> _saveRoleMember(LocalScheduleProvider localSch) async {
    await localSch.saveSchedule(widget.scheduleId);
  }
}
