import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/playlist/playlist.dart';
import 'package:cordeos/models/domain/schedule.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/screens/schedule/view.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/library/sheet_duplicate.dart';
import 'package:cordeos/widgets/schedule/library/sheet_share.dart';
import 'package:cordeos/widgets/schedule/status_chip.dart';

class ScheduleCard extends StatelessWidget {
  final int scheduleId;

  const ScheduleCard({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = context.read<MyAuthProvider>();
    final nav = context.read<NavigationProvider>();
    final user = context.read<UserProvider>();

    return Selector2<
      LocalScheduleProvider,
      PlaylistProvider,
      ({Schedule? schedule, Playlist? playlist})
    >(
      selector: (context, localSch, play) {
        final schedule = localSch.getSchedule(scheduleId);
        return (
          schedule: schedule,
          playlist: play.getPlaylist(schedule?.playlistId ?? -1),
        );
      },
      builder: (context, s, child) {
        // LOADING STATE
        if (s.schedule == null) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        String? userRole = AppLocalizations.of(context)!.generalMember;
        if (auth.id != null) {
          if (auth.id == s.schedule!.ownerFirebaseId) {
            userRole = AppLocalizations.of(context)!.owner;
          } else {
            final localID = user.getLocalIdByFirebaseId(auth.id!);
            for (var role in s.schedule!.roles.values) {
              if (role.users.any((u) => u.id == localID)) {
                userRole = role.name;
                break;
              }
            }
          }
        }

        return GestureDetector(
          onTap: () {
            final localVer = context.read<LocalVersionProvider>();
            final sect = context.read<SectionProvider>();
            final flow = context.read<FlowItemProvider>();
            final play = context.read<PlaylistProvider>();
            final sel = context.read<SelectionProvider>();
            final localSch = context.read<LocalScheduleProvider>();

            nav.push(
              () => ViewScheduleScreen(scheduleID: scheduleId),
              showBottomNavBar: true,
              keepAlive: true,
              changeDetector: () {
                return play.hasUnsavedChanges ||
                    flow.hasUnsavedChanges ||
                    localVer.hasUnsavedChanges ||
                    sect.hasUnsavedChanges ||
                    localSch.hasUnsavedChanges;
              },
              onChangeDiscarded: () async {
                debugPrint('PLAYLIST VIEW - discarding Changes');
                play.loadPlaylist(s.playlist!.id);
                localSch.loadSchedule(scheduleId);
                for (var id in sel.newlyAddedVersionIds) {
                  debugPrint('\t - deleting version with id $id');
                  await localVer.deleteVersion(id);
                  await sect.deleteSectionsOfVersion(id);
                }
                play.clearUnsavedChanges();
                flow.deleteCachedCreations();
                localVer.clearUnsavedChanges();
                sect.clearUnsavedChanges();
                sel.clearNewlyAddedVersionIds();
              },
            );
          },
          child: Container(
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
                IntrinsicHeight(
                  child: Row(
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
                                StatusChip(status: s.schedule!.scheduleState),
                              ],
                            ),

                            // WHEN & WHERE
                            Wrap(
                              spacing: 16.0,
                              children: [
                                Text(
                                  DateTimeUtils.formatDate(s.schedule!.date),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  DateTimeUtils.formatTime(s.schedule!.date),
                                ),
                                Text(
                                  s.schedule!.location,
                                  style: theme.textTheme.bodyMedium!,
                                ),
                              ],
                            ),

                            // PLAYLIST INFO
                            s.playlist != null
                                ? Text(
                                    '${AppLocalizations.of(context)!.playlist}: ${s.playlist!.name}',
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
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openScheduleActionsSheet(context),
                        child: SizedBox(
                          width: 40,
                          height: double.infinity,
                          child: Icon(Icons.more_vert),
                        ),
                      ),
                    ],
                  ),
                ),
                //share
                if (s.schedule!.ownerFirebaseId == auth.id &&
                    s.schedule!.scheduleState == ScheduleState.published)
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.share,
                    isDense: true,
                    isDark: true,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ShareScheduleSheet(scheduleID: scheduleId),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openScheduleActionsSheet(BuildContext context) {
    final localSch = context.read<LocalScheduleProvider>();

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
            spacing: 16,
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
                trailingIcon: Icons.chevron_right,
                onPressed: () {
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
                },
              ),

              // delete
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                tooltip: AppLocalizations.of(context)!.deleteScheduleTooltip,
                trailingIcon: Icons.chevron_right,
                isDangerous: true,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.schedule,
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          await localSch.deleteSchedule(scheduleId);
                        },
                      );
                    },
                  );
                },
              ),

              SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
