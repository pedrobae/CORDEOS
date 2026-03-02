import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/details_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DuplicateScheduleSheet extends StatefulWidget {
  final dynamic scheduleId;

  const DuplicateScheduleSheet({super.key, required this.scheduleId});

  @override
  State<DuplicateScheduleSheet> createState() => _DuplicateScheduleSheetState();
}

class _DuplicateScheduleSheetState extends State<DuplicateScheduleSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController roomVenueController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final cloudScheduleProvider = context.read<CloudScheduleProvider>();

      final dynamic schedule = widget.scheduleId is int
          ? localScheduleProvider.getSchedule(widget.scheduleId)!
          : cloudScheduleProvider.getSchedule(widget.scheduleId);

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
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    locationController.dispose();
    roomVenueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer5<
      LocalScheduleProvider,
      CloudScheduleProvider,
      UserProvider,
      MyAuthProvider,
      PlaylistProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            userProvider,
            authProvider,
            playlistProvider,
            child,
          ) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.duplicatePlaceholder(
                            AppLocalizations.of(context)!.schedule,
                          ),
                          style: textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    // FORM
                    ScheduleForm(
                      nameController: nameController,
                      dateController: dateController,
                      startTimeController: startTimeController,
                      locationController: locationController,
                      roomVenueController: roomVenueController,
                    ),

                    // ACTIONS
                    // confirm
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.keepGoing,
                      isDark: true,
                      onPressed: () async {
                        if (widget.scheduleId is int) {
                          localScheduleProvider.duplicateSchedule(
                            widget.scheduleId,
                            nameController.text,
                            dateController.text,
                            startTimeController.text,
                            locationController.text,
                            roomVenueController.text,
                          );
                        } else {
                          final scheduleDto = cloudScheduleProvider
                              .duplicateSchedule(
                                widget.scheduleId,
                                nameController.text,
                                dateController.text,
                                startTimeController.text,
                                locationController.text,
                                roomVenueController.text,
                              );

                          final ownerLocalId = userProvider
                              .getLocalIdByFirebaseId(authProvider.id!)!;

                          final playlistId = await playlistProvider
                              .createPlaylistFromDomain(
                                scheduleDto.playlist.toDomain(ownerLocalId),
                              );

                          localScheduleProvider.createSchedule(
                            scheduleDto.toDomain(playlistLocalId: playlistId),
                          );
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),

                    // cancel
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.cancel,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
    );
  }
}
