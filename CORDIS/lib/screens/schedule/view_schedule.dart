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
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);

    return Consumer3<
      LocalScheduleProvider,
      CloudScheduleProvider,
      PlaylistProvider
    >(
      builder: (context, localSch, cloudSch, play, child) {
        if (localSch.isLoading ||
            cloudSch.isLoading ||
            (isCloud && cloudSch.syncingStatus[widget.scheduleId] == true)) {
          return _buildLoadingState(nav);
        }

        if (localSch.error != null && cloudSch.error != null) {
          return _buildErrorState(nav, localSch, cloudSch);
        }

        final schedule = isCloud
            ? cloudSch.getSchedule(widget.scheduleId)
            : localSch.getSchedule(widget.scheduleId);

        if (schedule == null) {
          return _buildNotFoundState(nav);
        }

        final playlist = _getPlaylist(schedule, play, user);
        final memberCount = _getMemberCount(schedule);

        return _buildContent(
          nav,
          localSch,
          play,
          schedule,
          playlist,
          memberCount,
        );
      },
    );
  }

  Scaffold _buildLoadingState(NavigationProvider nav) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loading),
        leading: BackButton(onPressed: () => nav.attemptPop(context)),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _buildErrorState(
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    CloudScheduleProvider cloudSch,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.error),
        leading: BackButton(onPressed: () => nav.attemptPop(context)),
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.errorMessage(
                AppLocalizations.of(context)!.load,
                localSch.error ?? cloudSch.error ?? '',
              ),
              style: const TextStyle(color: Colors.red),
            ),
            ElevatedButton(
              onPressed: () {
                localSch.loadSchedules();
                cloudSch.loadSchedules(context.read<MyAuthProvider>().id!);
                for (var schedule in cloudSch.schedules.values) {
                  for (var versionEntry in schedule.playlist.versions.entries) {
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

  Scaffold _buildNotFoundState(NavigationProvider nav) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scheduleNotFound),
        leading: BackButton(onPressed: () => nav.attemptPop(context)),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.scheduleNotFoundMessage),
      ),
    );
  }

  Scaffold _buildContent(
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    PlaylistProvider play,
    dynamic schedule,
    dynamic playlist,
    int memberCount,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _buildAppBar(nav, textTheme),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            spacing: 28,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScheduleDetails(nav, localSch, schedule),
              _buildPlaylistSection(nav, play, playlist),
              _buildMembersSection(nav, localSch, schedule),
              _buildPublishButton(schedule),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(NavigationProvider nav, TextTheme textTheme) {
    return AppBar(
      title: Text(
        AppLocalizations.of(
          context,
        )!.viewPlaceholder(AppLocalizations.of(context)!.schedule),
        style: textTheme.titleMedium,
      ),
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
      actions: [
        IconButton(
          icon: const Icon(Icons.play_circle_fill),
          onPressed: () {
            context.read<NavigationProvider>().push(
              PlayScheduleScreen(scheduleId: widget.scheduleId),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScheduleDetails(
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    dynamic schedule,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
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
                  Text(schedule.name, style: textTheme.headlineSmall),
                  StatusChip(schedule: schedule),
                ],
              ),
              Row(
                spacing: 16,
                children: [
                  Text(
                    DateTimeUtils.formatDate(_getScheduleDate(schedule)),
                    style: textTheme.bodySmall,
                  ),
                  Text(
                    _formatScheduleTime(schedule),
                    style: textTheme.bodySmall,
                  ),
                  Text(schedule.location, style: textTheme.bodySmall),
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
              text: AppLocalizations.of(context)!.editPlaceholder(''),
              onPressed: () {
                nav.push(
                  EditScheduleScreen(
                    mode: EditScheduleMode.details,
                    scheduleId: widget.scheduleId,
                  ),
                  changeDetector: () => localSch.hasUnsavedChanges,
                  showBottomNavBar: true,
                );
              },
              isDark: true,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistSection(
    NavigationProvider nav,
    PlaylistProvider play,
    dynamic playlist,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.surfaceContainerLowest,
                  ),
                ),
                if (playlist == null)
                  Text(
                    AppLocalizations.of(context)!.noPlaylistAssigned,
                    style: textTheme.titleMedium,
                  )
                else ...[
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
              ],
            ),
          ),
          SizedBox(
            width: 75,
            child: FilledTextButton(
              isDisabled: playlist == null,
              text: AppLocalizations.of(context)!.editPlaceholder(''),
              onPressed: () {
                if (isCloud) return;
                nav.push(
                  ViewPlaylistScreen(playlistId: playlist!.id),
                  changeDetector: () => play.hasUnsavedChanges,
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

  Widget _buildMembersSection(
    NavigationProvider nav,
    LocalScheduleProvider localSch,
    dynamic schedule,
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
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.surfaceContainerLowest,
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
                    style: textTheme.bodySmall,
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
                  EditScheduleScreen(
                    mode: EditScheduleMode.roleMember,
                    scheduleId: widget.scheduleId,
                  ),
                  changeDetector: () =>
                      (localSch.hasUnsavedChanges ||
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
    );
  }

  Widget _buildPublishButton(dynamic schedule) {
    if (isCloud || schedule.isPublic == true) {
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
                      onPressed: () {
                        _publishSchedule();
                        Navigator.of(context).pop();
                        context.read<NavigationProvider>().pop();
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

  dynamic _getPlaylist(
    dynamic schedule,
    PlaylistProvider play,
    UserProvider user,
  ) {
    if (!isCloud) {
      return play.getPlaylistById((schedule as Schedule).playlistId!);
    } else {
      final dto = schedule as ScheduleDto;
      return dto.playlist.toDomain(
        user.getLocalIdByFirebaseId(dto.ownerFirebaseId)!,
      );
    }
  }

  int _getMemberCount(dynamic schedule) {
    int count = 0;
    final roles = isCloud ? (schedule as ScheduleDto).roles : (schedule as Schedule).roles;
    for (var role in roles) {
      final userCount = isCloud
          ? (role as RoleDto).users.length
          : (role as Role).users.length;
      count += userCount;
    }
    return count;
  }

  String _formatScheduleTime(dynamic schedule) {
    if (!isCloud) {
      return (schedule as Schedule).time.format(context);
    } else {
      final dt = (schedule as ScheduleDto).datetime.toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  DateTime _getScheduleDate(dynamic schedule) {
    if (!isCloud) {
      return (schedule as Schedule).date;
    } else {
      return (schedule as ScheduleDto).datetime.toDate();
    }
  }

  void _publishSchedule() {
    final cloudSch = context.read<CloudScheduleProvider>();
    final localSch = context.read<LocalScheduleProvider>();
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();
    final flow = context.read<FlowItemProvider>();

    final domainSchedule = localSch.getSchedule(widget.scheduleId)!;

    final domainPlaylist = play.getPlaylistById(domainSchedule.playlistId!)!;

    // Build Item DTOs
    final itemOrder = <String>[];
    final flowItems = <String, FlowItem>{};
    final versions = <String, VersionDto>{};
    for (var item in domainPlaylist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = localVer.cachedVersion(item.contentId!);

          if (version == null) break;
          String firebaseId;
          if (version.firebaseId == null) {
            firebaseId = generateFirebaseId();
            localVer.updateVersion(version.copyWith(firebaseId: firebaseId));
          } else {
            firebaseId = version.firebaseId!;
          }

          final cipher = ciph.getCipher(version.cipherId);

          if (cipher == null) break;
          versions['v:$firebaseId'] = version.toDto(cipher);
          break;
        case PlaylistItemType.flowItem:
          final flowItem = flow.getFlowItem(item.contentId!);
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

    cloudSch.publishSchedule(
      domainSchedule.toDto(
        domainPlaylist.toDto(
          itemOrder: itemOrder,
          flowItems: flowItems,
          versions: versions,
        ),
      ),
    );

    localSch.publishSchedule(widget.scheduleId);
  }
}
