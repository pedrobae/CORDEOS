import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/screens/schedule/view.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/library/sheet_duplicate.dart';
import 'package:cordis/widgets/schedule/library/sheet_share.dart';
import 'package:cordis/widgets/schedule/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleCard extends StatelessWidget {
  final int scheduleId;
  final bool showActions;

  const ScheduleCard({
    super.key,
    required this.scheduleId,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer5<
      LocalScheduleProvider,
      PlaylistProvider,
      MyAuthProvider,
      UserProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            playlistProvider,
            authProvider,
            userProvider,
            navigationProvider,
            child,
          ) {
            // LOADING STATE
            if (localScheduleProvider.isLoading ||
                userProvider.isLoading ||
                scheduleId == -1) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final schedule = localScheduleProvider.getSchedule(scheduleId);

            final playlist = playlistProvider.getPlaylist(
              schedule!.playlistId,
            );

            String? userRole = AppLocalizations.of(context)!.generalMember;
            if (authProvider.id != null) {
              if (authProvider.id == schedule.ownerFirebaseId) {
                userRole = AppLocalizations.of(context)!.owner;
              } else {
                userRole = localScheduleProvider.getUserRoleInSchedule(
                  scheduleId,
                  userProvider.getLocalIdByFirebaseId(authProvider.id!),
                );
              }
            }

            return Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.surfaceContainerLowest,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
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
                                StatusChip(schedule: schedule),
                              ],
                            ),

                            // WHEN & WHERE
                            Wrap(
                              spacing: 16.0,
                              children: [
                                Text(
                                  DateTimeUtils.formatDate(schedule.date),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(DateTimeUtils.formatTime(schedule.date)),
                                Text(
                                  schedule.location,
                                  style: theme.textTheme.bodyMedium!,
                                ),
                              ],
                            ),

                            // PLAYLIST INFO
                            playlist != null
                                ? Text(
                                    '${AppLocalizations.of(context)!.playlist}: ${playlist.name}',
                                    style: theme.textTheme.bodyMedium,
                                  )
                                : SizedBox.shrink(),

                            // YOUR ROLE INFO
                            Text(
                              '${AppLocalizations.of(context)!.role}: $userRole',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (showActions) ...[
                        IconButton(
                          onPressed: () => _openScheduleActionsSheet(
                            context,
                            scheduleId,
                            localScheduleProvider,
                          ),
                          icon: Icon(Icons.more_vert),
                        ),
                      ],
                    ],
                  ),
                  // BOTTOM BUTTONS
                  //view
                  FilledTextButton(
                    isDark: true,
                    isDense: true,
                    text: AppLocalizations.of(
                      context,
                    )!.viewPlaceholder(AppLocalizations.of(context)!.schedule),
                    onPressed: () {
                      navigationProvider.push(
                        () => ViewScheduleScreen(scheduleId: scheduleId),
                        showBottomNavBar: true,
                      );
                    },
                  ),
                  //share
                  if (schedule.ownerFirebaseId == authProvider.id && schedule.scheduleState == ScheduleState.published)
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.share,
                      isDense: true,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: ShareScheduleSheet(scheduleId: scheduleId),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
    );
  }

  void _openScheduleActionsSheet(
    BuildContext context,
    int scheduleId,
    LocalScheduleProvider localScheduleProvider,
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
                tooltip: AppLocalizations.of(
                  context,
                )!.duplicateTooltip(AppLocalizations.of(context)!.setup),
                onPressed: () =>
                    _openDuplicateScheduleSheet(context, scheduleId),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
              ),

              // delete
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                tooltip: AppLocalizations.of(context)!.deleteScheduleTooltip,
                trailingIcon: Icons.chevron_right,
                isDangerous: true,
                isDiscrete: true,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.schedule,
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          await localScheduleProvider.deleteSchedule(
                            scheduleId,
                          );
                        },
                      );
                    },
                  );
                },
              ),

              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openDuplicateScheduleSheet(BuildContext context, int scheduleId) {
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
