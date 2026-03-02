import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/screens/schedule/play_schedule.dart';
import 'package:cordis/widgets/schedule/status_chip.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/duplicate_schedule_sheet.dart';

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

    return Consumer5<
      CloudScheduleProvider,
      PlaylistProvider,
      MyAuthProvider,
      UserProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            cloudScheduleProvider,
            playlistProvider,
            authProvider,
            userProvider,
            navigationProvider,
            child,
          ) {
            // LOADING STATE
            if (cloudScheduleProvider.isLoading ||
                userProvider.isLoading ||
                scheduleId == '-1') {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final schedule = cloudScheduleProvider.getSchedule(scheduleId)!;

            final playlist = schedule.playlist;

            String userRole = AppLocalizations.of(context)!.generalMember;

            for (var role in schedule.roles) {
              if (role.users.any(
                (user) => user.firebaseId == authProvider.id,
              )) {
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
                                      schedule.name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    StatusChip(
                                      schedule: schedule.toDomain(
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
                                        schedule.datetime.toDate(),
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      DateTimeUtils.formatDate(
                                        schedule.datetime.toDate(),
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      schedule.location,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),

                                // PLAYLIST INFO
                                Text(
                                  '${AppLocalizations.of(context)!.playlist}: ${playlist.name}',
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
                            if (cloudScheduleProvider
                                    .syncingStatus[scheduleId] ==
                                true) ...[
                              SizedBox(
                                height: 35,
                                width: 35,
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onSurface,
                                        strokeWidth: 5,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceTint,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.cloud_download,
                                          size: 25,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (showActions) ...[
                              IconButton(
                                onPressed: () => _openScheduleActionsSheet(
                                  context,
                                  scheduleId,
                                  cloudScheduleProvider,
                                ),
                                icon: Icon(Icons.more_vert),
                              ),
                            ],
                          ],
                        ),
                        // BOTTOM BUTTONS
                        FilledTextButton(
                          isDark: true,
                          isDense: true,
                          onPressed: () {
                            navigationProvider.push(
                              PlayScheduleScreen(scheduleId: scheduleId),
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

  void _openScheduleActionsSheet(
    BuildContext context,
    dynamic scheduleId,
    CloudScheduleProvider cloudScheduleProvider,
  ) {
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
                          cloudScheduleProvider.deleteSchedule(
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
