import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/section_provider.dart';
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
import 'package:cordeos/providers/auto_scroll_provider.dart';
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
  final int scheduleId;

  const ViewScheduleScreen({super.key, required this.scheduleId});

  @override
  State<ViewScheduleScreen> createState() => _ViewScheduleScreenState();
}

class _ViewScheduleScreenState extends State<ViewScheduleScreen> {
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final playlistProvider = context.read<PlaylistProvider>();

      final schedule = localScheduleProvider.getSchedule(widget.scheduleId)!;
      playlistProvider.loadPlaylist(schedule.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Consumer2<LocalScheduleProvider, PlaylistProvider>(
      builder: (context, localSch, play, child) {
        final schedule = localSch.getSchedule(widget.scheduleId);

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
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  nav.push(
                    () => EditDetails(scheduleID: widget.scheduleId),
                    changeDetector: () => localSch.hasUnsavedChanges,
                    onChangeDiscarded: () =>
                        localSch.loadSchedule(widget.scheduleId),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Builder(
                builder: (context) {
                  if (schedule == null) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    spacing: 28,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildScheduleDetails(nav, localSch, schedule),
                      _buildPlaylistSection(nav, play, schedule),
                      _buildMembersSection(nav, localSch, schedule),
                      _buildPublishButton(schedule),
                      if (_isPublishing) ...[
                        Center(child: CloudDownloadIndicator(isUpload: true)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleDetails(
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    Schedule schedule,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.name, style: textTheme.titleLarge),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      Text(
                        DateTimeUtils.formatDate(schedule.date),
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        DateTimeUtils.formatTime(
                          DateTime(
                            0,
                            0,
                            0,
                            schedule.time.hour,
                            schedule.time.minute,
                          ),
                        ),
                        style: textTheme.bodyMedium,
                      ),
                      Text(schedule.location, style: textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
              StatusChip(schedule: schedule),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.play_circle, size: 32),
          onPressed: () async {
            final scroll = context.read<ScrollProvider>();
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.immersiveSticky,
            );
            nav.push(
              () => PlaySchedule(scheduleId: widget.scheduleId),
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

  Widget _buildPlaylistSection(
    NavigationProvider nav,
    PlaylistProvider play,
    Schedule schedule,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Builder(
      builder: (context) {
        final playlist = play.getPlaylist(schedule.playlistId);

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
              SizedBox(
                width: 75,
                child: FilledTextButton(
                  text: AppLocalizations.of(context)!.editPlaceholder(''),
                  onPressed: () {
                    final sel = context.read<SelectionProvider>();
                    final localVer = context.read<LocalVersionProvider>();
                    final sect = context.read<SectionProvider>();
                    final flow = context.read<FlowItemProvider>();

                    nav.push(
                      () => ViewPlaylistScreen(playlistId: playlist.id),
                      changeDetector: () {
                        return play.hasUnsavedChanges || flow.hasUnsavedChanges;
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
                        flow.clearUnsavedChanges();
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

  Widget _buildMembersSection(
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    Schedule schedule,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final memberCount = _getMemberCount(schedule);

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
                if (schedule.roles.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.noRoles,
                    style: textTheme.titleMedium,
                  )
                else ...[
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
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 75,
            child: FilledTextButton(
              text: AppLocalizations.of(context)!.editPlaceholder(''),
              onPressed: () {
                nav.push(
                  () => EditRoles(scheduleId: widget.scheduleId),
                  changeDetector: () => localSch.hasUnsavedChanges,
                  onChangeDiscarded: () =>
                      localSch.loadSchedule(widget.scheduleId),
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
  }

  Widget _buildPublishButton(Schedule schedule) {
    if (schedule.isPublic == true) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                        AppLocalizations.of(context)!.publishScheduleWarning,
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
  }

  int _getMemberCount(Schedule schedule) {
    int count = 0;
    final roles = schedule.roles;
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

    final schedule = localSch.getSchedule(widget.scheduleId);

    if (schedule == null) {
      debugPrint('Error: Schedule not found for publishing');
      return;
    }

    await syncService.upsertScheduleToCloud(schedule, auth.id!);

    setState(() {
      _isPublishing = false;
    });
  }
}
