import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/screens/schedule/play.dart';
import 'package:cordis/widgets/common/cloud_download_indicator.dart';
import 'package:cordis/widgets/schedule/status_chip.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/sheet_duplicate.dart';

import 'package:flutter/material.dart';

class CloudScheduleCard extends StatelessWidget {
  final String scheduleId;
  final bool showActions;

  const CloudScheduleCard({
    super.key,
    required this.scheduleId,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = context.read<MyAuthProvider>();
    final nav = context.read<NavigationProvider>();

    return Selector<
      CloudScheduleProvider,
      ({ScheduleDto? schedule, bool isLoading, bool isSyncing})
    >(
      selector: (context, cloudSch) => (
        schedule: cloudSch.getSchedule(scheduleId),
        isLoading: cloudSch.isLoading,
        isSyncing: cloudSch.syncingStatus(scheduleId),
      ),
      builder: (context, selection, child) {
        // LOADING STATE
        if (selection.isLoading || selection.schedule == null) {
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                Icon(Icons.cloud, size: 20, color: colorScheme.primary),
              ],
            ),
          );
        }

        String userRole = AppLocalizations.of(context)!.generalMember;

        for (var role in selection.schedule!.roles) {
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
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SCHEDULE NAME
                            Row(
                              spacing: 8,
                              children: [
                                Text(
                                  selection.schedule!.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                StatusChip(
                                  schedule: selection.schedule!.toDomain(
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
                                    selection.schedule!.datetime.toDate(),
                                  ),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  DateTimeUtils.formatTime(
                                    selection.schedule!.datetime.toDate(),
                                  ),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  selection.schedule!.location,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),

                            // PLAYLIST INFO
                            Text(
                              '${AppLocalizations.of(context)!.playlist}: ${selection.schedule!.playlist.name}',
                              style: theme.textTheme.bodyMedium,
                            ),

                            // YOUR ROLE INFO
                            Text(
                              '${AppLocalizations.of(context)!.role}: $userRole',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Spacer(),
                        if (selection.isSyncing) const CloudDownloadIndicator(),
                        if (showActions)
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
                        final scroll = context.read<AutoScrollProvider>();

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
