import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/screens/schedule/play.dart';
import 'package:cordeos/widgets/common/cloud_download_indicator.dart';
import 'package:cordeos/widgets/schedule/status_chip.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/schedule/cloud_schedule_provider.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/library/sheet_duplicate.dart';

import 'package:flutter/material.dart';

class CloudScheduleCard extends StatelessWidget {
  final String scheduleId;

  const CloudScheduleCard({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = context.read<MyAuthProvider>();
    final nav = context.read<NavigationProvider>();

    return Selector<
      CloudScheduleProvider,
      ({ScheduleDto? schedule, bool isSyncing})
    >(
      selector: (context, cloudSch) => (
        schedule: cloudSch.getSchedule(scheduleId),
        isSyncing: cloudSch.syncingStatus(scheduleId),
      ),
      builder: (context, s, child) {
        String userRole = AppLocalizations.of(context)!.generalMember;

        for (var role in s.schedule!.roles) {
          if (role.users.any((user) => user.firebaseId == auth.id)) {
            userRole = role.name;
            break;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Stack(
            children: [
              // CLOUD WATERMARK
              Positioned(
                right: -20,
                bottom: -50,
                child: Icon(
                  Icons.cloud,
                  size: 250,
                  color: colorScheme.surfaceTint,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.surfaceContainerLowest,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // SCHEDULE NAME
                              Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    s.schedule!.name,
                                    style: theme.textTheme.titleMedium,
                                    softWrap: true,
                                  ),
                                  StatusChip(
                                    schedule: s.schedule!.toDomain(
                                      playlistLocalId: -1,
                                    ),
                                  ),
                                ],
                              ),
                          
                              // WHEN & WHERE
                              Wrap(
                                spacing: 16.0,
                                children: [
                                  Text(
                                    DateTimeUtils.formatDate(
                                      s.schedule!.datetime.toDate(),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    DateTimeUtils.formatTime(
                                      s.schedule!.datetime.toDate(),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    s.schedule!.location,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                          
                              // PLAYLIST INFO
                              Text(
                                '${AppLocalizations.of(context)!.playlist}: ${s.schedule!.playlist.name}',
                                style: theme.textTheme.bodyMedium,
                              ),
                          
                              // YOUR ROLE INFO
                              Text(
                                '${AppLocalizations.of(context)!.role}: $userRole',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (s.isSyncing) const CloudDownloadIndicator(),
                        IconButton(
                          onPressed: () => _openScheduleActionsSheet(context),
                          icon: Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                    
                    // BOTTOM BUTTONS
                    FilledTextButton(
                      isDark: true,
                      isDense: true,
                      onPressed: () async {
                        final scroll = context.read<ScrollProvider>();

                        await SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky,
                        );

                        nav.push(
                          () => PlaySchedule(scheduleId: scheduleId),
                          onPopCallback: () async {
                            await SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.edgeToEdge,
                            );
                            scroll.clearCache();
                          },
                        );
                      },
                      text: AppLocalizations.of(context)!.play,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openScheduleActionsSheet(BuildContext context) {
    final cloudSch = context.read<CloudScheduleProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.scheduleActions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // ACTIONS
              // duplicate
              FilledTextButton(
                text: AppLocalizations.of(context)!.duplicatePlaceholder(''),
                tooltip: AppLocalizations.of(context)!.createLocalCopy,
                onPressed: () =>
                    _openDuplicateScheduleSheet(context, scheduleId),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
              ),
              // delete
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                tooltip: AppLocalizations.of(context)!.deleteScheduleTooltip,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.schedule,
                        onConfirm: () {
                          Navigator.of(context).pop();
                          cloudSch.deleteSchedule(
                            context.read<MyAuthProvider>().id!,
                            scheduleId,
                          );
                        },
                      );
                    },
                  );
                },
                trailingIcon: Icons.chevron_right,
                isDangerous: true,
                isDiscrete: true,
              ),

              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openDuplicateScheduleSheet(BuildContext context, dynamic scheduleId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DuplicateScheduleSheet(scheduleId: scheduleId),
        );
      },
    );
  }
}
