import 'package:cordis/helpers/codes.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/playlist/view_playlist.dart';
import 'package:cordis/screens/schedule/edit_schedule.dart';
import 'package:cordis/screens/schedule/play_schedule.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewScheduleScreen extends StatefulWidget {
  final dynamic scheduleId;

  const ViewScheduleScreen({super.key, required this.scheduleId});

  @override
  State<ViewScheduleScreen> createState() => _ViewScheduleScreenState();
}

class _ViewScheduleScreenState extends State<ViewScheduleScreen> {
  late bool isCloud;

  @override
  void initState() {
    super.initState();
    isCloud = widget.scheduleId is String;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final cloudScheduleProvider = context.read<CloudScheduleProvider>();
      final playlistProvider = context.read<PlaylistProvider>();

      if (isCloud) {
        final schedule = cloudScheduleProvider.getSchedule(widget.scheduleId)!;
        playlistProvider.setPlaylist(
          schedule.playlist.toDomain(
            context.read<UserProvider>().getLocalIdByFirebaseId(
                  schedule.ownerFirebaseId,
                ) ??
                -1,
          ),
        );
      } else {
        final schedule = localScheduleProvider.getSchedule(widget.scheduleId)!;
        if (schedule.playlistId != null) {
          playlistProvider.loadPlaylist(schedule.playlistId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      LocalScheduleProvider,
      CloudScheduleProvider,
      PlaylistProvider,
      NavigationProvider,
      SelectionProvider,
      UserProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            playlistProvider,
            navigationProvider,
            selectionProvider,
            userProvider,
            child,
          ) {
            // LOADING STATE
            if (localScheduleProvider.isLoading ||
                cloudScheduleProvider.isLoading ||
                (isCloud &&
                    cloudScheduleProvider.syncingStatus[widget.scheduleId] ==
                        true)) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.loading),
                  leading: BackButton(
                    onPressed: () {
                      navigationProvider.attemptPop(context);
                    },
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            // ERROR STATE
            if (localScheduleProvider.error != null &&
                cloudScheduleProvider.error != null) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.error),
                  leading: BackButton(
                    onPressed: () {
                      navigationProvider.attemptPop(context);
                    },
                  ),
                ),
                body: Center(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.errorMessage(
                          AppLocalizations.of(context)!.load,
                          localScheduleProvider.error ??
                              cloudScheduleProvider.error ??
                              '',
                        ),
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          localScheduleProvider.loadSchedules();
                          cloudScheduleProvider.loadSchedules(
                            context.read<MyAuthProvider>().id!,
                          );
                          for (var schedule
                              in cloudScheduleProvider.schedules.values) {
                            for (var versionEntry
                                in schedule.playlist.versions.entries) {
                              context.read<CloudVersionProvider>().setVersion(
                                versionEntry.key,
                                versionEntry.value,
                              );
                            }
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.tryAgain),
                      ),
                    ],
                  ),
                ),
              );
            }

            // FETCH SCHEDULE DEPENDING ON PROVIDER
            final dynamic schedule = isCloud
                ? cloudScheduleProvider.getSchedule(widget.scheduleId)
                : localScheduleProvider.getSchedule(widget.scheduleId);

            if (schedule == null) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.scheduleNotFound),
                  leading: BackButton(
                    onPressed: () {
                      navigationProvider.attemptPop(context);
                    },
                  ),
                ),
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!.scheduleNotFoundMessage,
                  ),
                ),
              );
            }

            final playlist = schedule is Schedule
                ? playlistProvider.getPlaylistById(schedule.playlistId!)
                : (schedule as ScheduleDto).playlist.toDomain(
                    userProvider.getLocalIdByFirebaseId(
                      schedule.ownerFirebaseId,
                    )!,
                  );

            int memberCount = 0;
            for (var role in schedule.roles) {
              memberCount += role.users.length as int;
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppLocalizations.of(
                    context,
                  )!.viewPlaceholder(AppLocalizations.of(context)!.schedule),
                  style: textTheme.titleMedium,
                ),
                leading: BackButton(
                  onPressed: () {
                    navigationProvider.attemptPop(context);
                  },
                ),
                actions: [
                  // PLAY MODE
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed: () {
                      navigationProvider.push(
                        PlayScheduleScreen(scheduleId: widget.scheduleId),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.surfaceContainerLowest,
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    spacing: 28,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SCHEDULE DETAILS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 4,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      schedule.name,
                                      style: textTheme.headlineSmall,
                                    ),
                                    StatusChip(schedule: schedule),
                                  ],
                                ),
                                Row(
                                  spacing: 16,
                                  children: [
                                    Text(
                                      DateTimeUtils.formatDate(
                                        (schedule is Schedule)
                                            ? schedule.date
                                            : (schedule as ScheduleDto).datetime
                                                  .toDate(),
                                      ),
                                      style: textTheme.bodySmall,
                                    ),
                                    Text(
                                      (schedule is Schedule)
                                          ? schedule.time.format(context)
                                          : '${schedule.datetime.toDate().hour.toString().padLeft(2, '0')}:${ //
                                            schedule.datetime.toDate().minute.toString().padLeft(2, '0')}',
                                      style: textTheme.bodySmall,
                                    ),
                                    Text(
                                      schedule.location,
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 9.0),
                            child: SizedBox(
                              width: 75,
                              child: FilledTextButton(
                                text: AppLocalizations.of(
                                  context,
                                )!.editPlaceholder(''),
                                onPressed: () {
                                  navigationProvider.push(
                                    EditScheduleScreen(
                                      mode: EditScheduleMode.details,
                                      scheduleId: widget.scheduleId,
                                    ),
                                    changeDetector: () =>
                                        localScheduleProvider.hasUnsavedChanges,
                                    showBottomNavBar: true,
                                  );
                                },
                                isDark: true,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // PLAYLIST SECTION
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.surfaceContainerLowest,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.playlist,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.surfaceContainerLowest,
                                  ),
                                ),
                                if (playlist == null) ...[
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noPlaylistAssigned,
                                    style: textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  Text(
                                    playlist.name,
                                    style: textTheme.titleMedium,
                                  ),
                                  Row(
                                    spacing: 16,
                                    children: [
                                      Text(
                                        (playlist.items.length == 1)
                                            ? '1 ${AppLocalizations.of(context)!.item}'
                                            : '${playlist.items.length} ${AppLocalizations.of(context)!.pluralPlaceholder(
                                                AppLocalizations.of(context)!.item, //
                                              )}',
                                        style: textTheme.bodyMedium,
                                      ),
                                      Text(
                                        (playlist.getTotalDuration() ==
                                                Duration.zero)
                                            ? '-'
                                            : '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(playlist.getTotalDuration())}',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(
                              width: 75,
                              child: FilledTextButton(
                                isDisabled: playlist == null,
                                text: AppLocalizations.of(
                                  context,
                                )!.editPlaceholder(''),
                                onPressed: () {
                                  if (isCloud) return;
                                  navigationProvider.push(
                                    ViewPlaylistScreen(
                                      playlistId: playlist!.id,
                                    ),
                                    changeDetector: () =>
                                        playlistProvider.hasUnsavedChanges,
                                    showBottomNavBar: true,
                                  );
                                },
                                isDark: true,
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // MEMBERS SECTION
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.surfaceContainerLowest,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.roles} & ${AppLocalizations.of(context)!.pluralPlaceholder(AppLocalizations.of(context)!.member)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.surfaceContainerLowest,
                                  ),
                                ),
                                if (schedule.roles.isEmpty) ...[
                                  Text(
                                    AppLocalizations.of(context)!.noRoles,
                                    style: textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  Text(
                                    (schedule.roles.length == 1)
                                        ? '1 ${AppLocalizations.of(context)!.role}'
                                        : '${schedule.roles.length} ${AppLocalizations.of(context)!.roles}',
                                    style: textTheme.titleMedium,
                                  ),
                                  Text(
                                    (memberCount == 1)
                                        ? '1 ${AppLocalizations.of(context)!.member}'
                                        : '$memberCount ${AppLocalizations.of(context)!.pluralPlaceholder(AppLocalizations.of(context)!.member)}',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(
                              width: 75,
                              child: FilledTextButton(
                                text: AppLocalizations.of(
                                  context,
                                )!.editPlaceholder(''),
                                onPressed: () {
                                  navigationProvider.push(
                                    EditScheduleScreen(
                                      mode: EditScheduleMode.roleMember,
                                      scheduleId: widget.scheduleId,
                                    ),
                                    changeDetector: () =>
                                        (localScheduleProvider
                                            .hasUnsavedChanges ||
                                        context.read<SectionProvider>().hasUnsavedChanges ||
                                        context.read<CipherProvider>().hasUnsavedChanges),
                                    showBottomNavBar: true,
                                  );
                                },
                                isDark: true,
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // PUBLISH BUTTON
                      if (!isCloud && schedule.isPublic == false)
                        FilledTextButton(
                          isDark: true,
                          text: AppLocalizations.of(
                            context,
                          )!.publishPlaceholder(''),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(0),
                                      color: colorScheme.surface,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      spacing: 8,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.publishPlaceholder(
                                            AppLocalizations.of(
                                              context,
                                            )!.schedule,
                                          ),
                                          style: textTheme.headlineSmall,
                                          textAlign: TextAlign.center,
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 28,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.publishScheduleWarning,
                                            style: textTheme.bodySmall,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        FilledTextButton(
                                          text: AppLocalizations.of(
                                            context,
                                          )!.publishPlaceholder(''),
                                          isDark: true,
                                          onPressed: () {
                                            if (isCloud) return;
                                            _publishSchedule();
                                            Navigator.of(
                                              context,
                                            ).pop(); // CLOSE DIALOG
                                            navigationProvider
                                                .pop(); // GO BACK TO LIBRARY
                                          },
                                        ),
                                        FilledTextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          text: AppLocalizations.of(
                                            context,
                                          )!.cancel,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  void _publishSchedule() {
    final cloudScheduleProvider = context.read<CloudScheduleProvider>();
    final localScheduleProvider = context.read<LocalScheduleProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final cipherProvider = context.read<CipherProvider>();
    final flowItemProvider = context.read<FlowItemProvider>();

    final domainSchedule = localScheduleProvider.getSchedule(
      widget.scheduleId,
    )!;

    final domainPlaylist = playlistProvider.getPlaylistById(
      domainSchedule.playlistId!,
    )!;

    // Build Item DTOs
    final itemOrder = <String>[];
    final flowItems = <String, FlowItem>{};
    final versions = <String, VersionDto>{};
    for (var item in domainPlaylist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = localVersionProvider.cachedVersion(item.contentId!);

          if (version == null) break;
          String firebaseId;
          if (version.firebaseId == null) {
            firebaseId = generateFirebaseId();
            localVersionProvider.updateVersion(
              version.copyWith(firebaseId: firebaseId),
            );
          } else {
            firebaseId = version.firebaseId!;
          }

          final cipher = cipherProvider.getCipher(version.cipherId);

          if (cipher == null) break;
          versions['v:$firebaseId'] = version.toDto(cipher);
          break;
        case PlaylistItemType.flowItem:
          final flowItem = flowItemProvider.getFlowItem(item.contentId!);
          if (flowItem == null) break;

          String firebaseId;
          if (flowItem.firebaseId.isEmpty) {
            firebaseId = generateFirebaseId();
          } else {
            firebaseId = flowItem.firebaseId;
          }
          flowItems['f:$firebaseId'] = flowItem;
          break;
      }
    }

    cloudScheduleProvider.publishSchedule(
      domainSchedule.toDto(
        domainPlaylist.toDto(
          itemOrder: itemOrder,
          flowItems: flowItems,
          versions: versions,
        ),
      ),
    );

    localScheduleProvider.publishSchedule(widget.scheduleId);
  }
}
