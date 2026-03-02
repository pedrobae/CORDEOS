import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/playlist/playlist_library.dart';
import 'package:cordis/services/sync_service.dart';
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
    return Consumer4<
      SelectionProvider,
      NavigationProvider,
      LocalScheduleProvider,
      PlaylistProvider
    >(
      builder:
          (
            context,
            selectionProvider,
            navigationProvider,
            scheduleProvider,
            playlistProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;

            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => navigationProvider.attemptPop(context),
                ),
                title: Text(
                  AppLocalizations.of(context)!.editPlaceholder(
                    AppLocalizations.of(context)!.scheduleDetails,
                  ),
                  style: textTheme.titleMedium,
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // MODE CONTENT
                    Expanded(
                      child: switch (widget.mode) {
                        EditScheduleMode.details => ScheduleForm(
                          nameController: nameController,
                          dateController: dateController,
                          startTimeController: startTimeController,
                          locationController: locationController,
                          roomVenueController: roomVenueController,
                          annotationsController: annotationsController,
                        ),
                        EditScheduleMode.playlist => PlaylistLibraryScreen(),
                        EditScheduleMode.roleMember => RolesAndUsersForm(
                          scheduleId: widget.scheduleId,
                        ),
                      },
                    ),
                    // SAVE BUTTON
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.save,
                      onPressed: () {
                        switch (widget.mode) {
                          case EditScheduleMode.details:
                            _saveDetails(navigationProvider, scheduleProvider);
                            break;
                          case EditScheduleMode.playlist:
                            _savePlaylist(
                              navigationProvider,
                              scheduleProvider,
                              playlistProvider,
                              selectionProvider,
                            );
                            break;
                          case EditScheduleMode.roleMember:
                            _saveRoleMember(
                              navigationProvider,
                              scheduleProvider,
                            );
                            break;
                        }
                        // Sync to cloud if public
                        if (scheduleProvider.isPublished(widget.scheduleId)) {
                          scheduleProvider.uploadScheduleToCloud(
                            widget.scheduleId,
                            context.read<MyAuthProvider>().id!,
                          );
                        }
                        navigationProvider.pop();
                      },
                      isDisabled:
                          (selectionProvider.isSelectionMode &&
                          selectionProvider.selectedItemIds.length != 1),
                      isDark: true,
                    ),

                    // CANCEL BUTTON
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.cancel,
                      onPressed: () => navigationProvider.attemptPop(context),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Future<void> _saveDetails(
    NavigationProvider navigationProvider,
    LocalScheduleProvider scheduleProvider,
  ) async {
    scheduleProvider.cacheScheduleDetails(
      widget.scheduleId,
      name: nameController.text,
      date: dateController.text,
      startTime: startTimeController.text,
      location: locationController.text,
      roomVenue: roomVenueController.text,
      annotations: annotationsController.text,
    );
    await scheduleProvider.saveSchedule(widget.scheduleId);
    final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;
    if (schedule.isPublic && mounted) {
      await ScheduleSyncService().scheduleToCloud(
        schedule,
        context.read<MyAuthProvider>().id!,
      );
    }
  }

  Future<void> _savePlaylist(
    NavigationProvider navigationProvider,
    LocalScheduleProvider scheduleProvider,
    PlaylistProvider playlistProvider,
    SelectionProvider selectionProvider,
  ) async {
    if (selectionProvider.selectedItemIds.isEmpty) return;

    final selectedPlaylistId = selectionProvider.selectedItemIds.first as int;
    final selectedPlaylist = playlistProvider.getPlaylistById(
      selectedPlaylistId,
    );
    if (selectedPlaylist == null) return;

    scheduleProvider.assignPlaylistToSchedule(
      widget.scheduleId,
      selectedPlaylistId,
    );

    await scheduleProvider.saveSchedule(widget.scheduleId);

    final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;
    if (schedule.isPublic && mounted) {
      await ScheduleSyncService().scheduleToCloud(
        schedule,
        context.read<MyAuthProvider>().id!,
      );
    }
  }

  Future<void> _saveRoleMember(
    NavigationProvider navigationProvider,
    LocalScheduleProvider scheduleProvider,
  ) async {
    await scheduleProvider.saveSchedule(widget.scheduleId);
    final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;
    if (schedule.isPublic && mounted) {
      await ScheduleSyncService().scheduleToCloud(
        schedule,
        context.read<MyAuthProvider>().id!,
      );
    }
  }
}
