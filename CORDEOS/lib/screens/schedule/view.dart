import 'package:cordeos/models/domain/playlist/playlist.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/services/sync_service.dart';
import 'package:cordeos/widgets/common/cloud_download_indicator.dart';
import 'package:flutter/material.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/schedule.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';

import 'package:cordeos/screens/playlist/view_playlist.dart';
import 'package:cordeos/screens/schedule/play.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/create_edit/edit_details.dart';
import 'package:cordeos/widgets/schedule/create_edit/edit_roles.dart';
import 'package:cordeos/widgets/schedule/status_chip.dart';

class ViewScheduleScreen extends StatefulWidget {
  final dynamic scheduleID;

  ViewScheduleScreen({super.key, required this.scheduleID}) {
    assert(scheduleID is String || scheduleID is int);
  }

  @override
  State<ViewScheduleScreen> createState() => _ViewScheduleScreenState();
}

class _ViewScheduleScreenState extends State<ViewScheduleScreen> {
  late bool _isCloud;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();

    _isCloud = widget.scheduleID is String;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isCloud) {
        final localSch = context.read<LocalScheduleProvider>();
        final play = context.read<PlaylistProvider>();

        final schedule = localSch.getSchedule(widget.scheduleID)!;
        play.loadPlaylist(schedule.playlistId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final localSch = context.read<LocalScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!.viewPlaceholder(AppLocalizations.of(context)!.schedule),
          style: textTheme.titleMedium,
        ),
        leading: BackButton(onPressed: () => nav.attemptPop(context)),
        actions: [
          if (!_isCloud)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                nav.push(
                  () => EditDetails(scheduleID: widget.scheduleID),
                  changeDetector: () => localSch.hasUnsavedChanges,
                  onChangeDiscarded: () =>
                      localSch.loadSchedule(widget.scheduleID),
                  showBottomNavBar: true,
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.surfaceContainerLowest),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            spacing: 28,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScheduleDetails(),
              _buildPlaylistSection(),
              _buildMembersSection(),
              if (!_isCloud) _buildPublishButton(),
              if (_isPublishing) ...[
                Center(child: CloudDownloadIndicator(isUpload: true)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleDetails() {
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        Selector2<
          LocalScheduleProvider,
          CloudScheduleProvider,
          ({
            String name,
            String date,
            String time,
            String location,
            ScheduleState status,
          })
        >(
          selector: (context, localSch, cloudSch) {
            String name;
            String date;
            String time;
            String location;
            ScheduleState status;

            if (_isCloud) {
              final schedule = cloudSch.getSchedule(widget.scheduleID);
              if (schedule == null)
                throw Exception(
                  "Couldnt get cloud schedule ${widget.scheduleID}",
                );
              name = schedule.name;
              date = DateTimeUtils.formatDate(schedule.datetime.toDate());
              time = DateTimeUtils.formatTime(schedule.datetime.toDate());
              location = schedule.location;
              status = schedule.scheduleState;
            } else {
              final schedule = localSch.getSchedule(widget.scheduleID);
              if (schedule == null)
                throw Exception(
                  "Couldnt get local schedule ${widget.scheduleID}",
                );
              name = schedule.name;
              date = DateTimeUtils.formatDate(schedule.date);
              time = DateTimeUtils.formatTime(schedule.date);
              location = schedule.location;
              status = schedule.scheduleState;
            }

            return (
              name: name,
              date: date,
              time: time,
              location: location,
              status: status,
            );
          },
          builder: (context, s, child) {
            return Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: textTheme.titleLarge),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          Text(s.date, style: textTheme.bodyMedium),
                          Text(s.time, style: textTheme.bodyMedium),
                          Text(s.location, style: textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                  StatusChip(status: s.status),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.play_circle, size: 32),
          onPressed: () async {
            final scroll = context.read<ScrollProvider>();
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.immersiveSticky,
            );
            nav.push(
              () => PlaySchedule(scheduleId: widget.scheduleID),
              onPopCallback: () async {
                scroll.clearCache();
                await SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.edgeToEdge,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlaylistSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector3<
      PlaylistProvider,
      LocalScheduleProvider,
      CloudScheduleProvider,
      Playlist?
    >(
      selector: (context, play, localSch, cloudSch) {
        Playlist? playlist;
        if (_isCloud) {
          final schedule = cloudSch.getSchedule(widget.scheduleID);
          if (schedule == null)
            throw Exception("Couldnt get cloud schedule ${widget.scheduleID}");

          playlist = schedule.playlist.toDomain(-1);
        } else {
          final schedule = localSch.getSchedule(widget.scheduleID);
          if (schedule == null)
            throw Exception("Couldnt get local schedule ${widget.scheduleID}");

          playlist = play.getPlaylist(schedule.playlistId);
        }
        return playlist;
      },
      builder: (context, playlist, child) {
        if (playlist == null) {
          return Center(child: CircularProgressIndicator());
        }
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLowest),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.playlist,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(playlist.name, style: textTheme.titleMedium),
                    Row(
                      spacing: 16,
                      children: [
                        Text(
                          (playlist.items.length == 1)
                              ? '1 ${AppLocalizations.of(context)!.item}'
                              : '${playlist.items.length} ${AppLocalizations.of(context)!.pluralPlaceholder(AppLocalizations.of(context)!.item)}',
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          (playlist.getTotalDuration() == Duration.zero)
                              ? '-'
                              : '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(playlist.getTotalDuration())}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isCloud)
                SizedBox(
                  width: 75,
                  child: FilledTextButton(
                    text: AppLocalizations.of(context)!.editPlaceholder(''),
                    onPressed: () {
                      final sel = context.read<SelectionProvider>();
                      final localVer = context.read<LocalVersionProvider>();
                      final sect = context.read<SectionProvider>();
                      final flow = context.read<FlowItemProvider>();
                      final play = context.read<PlaylistProvider>();

                      nav.push(
                        () => ViewPlaylistScreen(playlistId: playlist.id),
                        changeDetector: () {
                          return play.hasUnsavedChanges ||
                              flow.hasUnsavedChanges;
                        },
                        onChangeDiscarded: () async {
                          debugPrint('PLAYLIST VIEW - discarding Changes');
                          play.loadPlaylist(playlist.id);
                          for (var id in sel.newlyAddedVersionIds) {
                            debugPrint('\t - deleting version with id $id');
                            await localVer.deleteVersion(id);
                            await sect.deleteSectionsOfVersion(id);
                          }
                          sel.clearNewlyAddedVersionIds();
                          play.clearUnsavedChanges();
                          flow.deleteCachedCreations();
                        },
                        showBottomNavBar: true,
                      );
                    },
                    isDark: true,
                    isDense: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector2<LocalScheduleProvider, CloudScheduleProvider, List<Role>>(
      selector: (context, localSch, cloudSch) {
        List<Role> roles = [];
        if (_isCloud) {
          final schedule = cloudSch.getSchedule(widget.scheduleID);
          if (schedule == null)
            throw Exception("Couldnt get cloud schedule ${widget.scheduleID}");

          roles = schedule.roles.map((e) => e.toDomain(-1)).toList();
        } else {
          final schedule = localSch.getSchedule(widget.scheduleID);
          if (schedule == null)
            throw Exception("Couldnt get local schedule ${widget.scheduleID}");

          roles = schedule.roles.values.toList();
        }
        return roles;
      },
      builder: (context, roles, child) {
        final memberCount = _getMemberCount(roles);
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLowest),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.roles} & ${AppLocalizations.of(context)!.pluralPlaceholder(AppLocalizations.of(context)!.member)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    if (roles.isEmpty)
                      Text(
                        AppLocalizations.of(context)!.noRoles,
                        style: textTheme.titleMedium,
                      )
                    else ...[
                      Text(
                        (roles.length == 1)
                            ? '1 ${AppLocalizations.of(context)!.role}'
                            : '${roles.length} ${AppLocalizations.of(context)!.roles}',
                        style: textTheme.titleMedium,
                      ),
                      Text(
                        (memberCount == 1)
                            ? '1 ${AppLocalizations.of(context)!.member}'
                            : '$memberCount ${AppLocalizations.of(context)!.pluralPlaceholder(AppLocalizations.of(context)!.member)}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isCloud)
                SizedBox(
                  width: 75,
                  child: FilledTextButton(
                    text: AppLocalizations.of(context)!.editPlaceholder(''),
                    onPressed: () {
                      final localSch = context.read<LocalScheduleProvider>();
                      nav.push(
                        () => EditRoles(scheduleId: widget.scheduleID),
                        changeDetector: () => localSch.hasUnsavedChanges,
                        onChangeDiscarded: () =>
                            localSch.loadSchedule(widget.scheduleID),
                        showBottomNavBar: true,
                      );
                    },
                    isDark: true,
                    isDense: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublishButton() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Selector<LocalScheduleProvider, bool>(
      selector: (context, localSch) =>
          localSch.getSchedule(widget.scheduleID)!.isPublic,
      builder: (context, isPublic, child) {
        if (isPublic) {
          return const SizedBox.shrink();
        }

        return FilledTextButton(
          isDark: true,
          text: AppLocalizations.of(context)!.publishPlaceholder(''),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.publishPlaceholder(
                            AppLocalizations.of(context)!.schedule,
                          ),
                          style: textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.publishScheduleWarning,
                            style: textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledTextButton(
                          text: AppLocalizations.of(
                            context,
                          )!.publishPlaceholder(''),
                          isDark: true,
                          onPressed: () async {
                            final nav = context.read<NavigationProvider>();
                            Navigator.of(context).pop();
                            await _publishSchedule();
                            nav.pop();
                          },
                        ),
                        FilledTextButton(
                          text: AppLocalizations.of(context)!.cancel,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  int _getMemberCount(List<Role> roles) {
    int count = 0;
    for (var role in roles) {
      final userCount = role.users.length;
      count += userCount;
    }
    return count;
  }

  Future<void> _publishSchedule() async {
    setState(() {
      _isPublishing = true;
    });
    final syncService = ScheduleSyncService();

    final localSch = context.read<LocalScheduleProvider>();
    final auth = context.read<MyAuthProvider>();

    final schedule = localSch.getSchedule(widget.scheduleID);

    if (schedule == null) {
      debugPrint('Error: Schedule not found for publishing');
      return;
    }

    await syncService.upsertScheduleToCloud(schedule, auth.id!);
    await localSch.loadSchedule(widget.scheduleID);

    setState(() {
      _isPublishing = false;
    });
  }
}
