import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';

import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';

import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';

import 'package:cordis/widgets/schedule/play/play_flow_item.dart';
import 'package:cordis/widgets/schedule/play/play_version.dart';
import 'package:cordis/widgets/settings/auto_scroll_settings.dart';
import 'package:cordis/widgets/settings/content_filters.dart';
import 'package:cordis/widgets/settings/style_settings.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayScheduleScreen extends StatefulWidget {
  final dynamic scheduleId;

  const PlayScheduleScreen({super.key, required this.scheduleId});

  @override
  State<PlayScheduleScreen> createState() => PlayScheduleScreenState();
}

class PlayScheduleScreenState extends State<PlayScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final bool isCloud = widget.scheduleId is String;
  late PlayScheduleStateProvider _stateProvider;

  @override
  void initState() {
    super.initState();
    _stateProvider = context.read<PlayScheduleStateProvider>();
    _stateProvider.reset();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
    });
  }

  /// Load only the current playlist structure without full content
  Future<void> _loadData() async {
    if (widget.scheduleId == null) throw Exception("Schedule ID is required");

    if (!isCloud) {
      await _loadLocal();
    } else {
      await _loadCloud();
    }
  }

  Future<void> _loadLocal() async {
    final scheduleProvider = context.read<LocalScheduleProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final flow = context.read<FlowItemProvider>();
    final state = context.read<PlayScheduleStateProvider>();

    final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;
    await playlistProvider.loadPlaylist(schedule.playlistId);

    final items = playlistProvider.getPlaylist(schedule.playlistId)!.items;
    state.setItems(items);
    for (var item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          await localVer.loadVersion(item.contentId!);

          break;
        case PlaylistItemType.flowItem:
          await flow.loadFlowItem(item.contentId!);
      }
    }
  }

  Future<void> _loadCloud() async {
    final cloudSch = context.read<CloudScheduleProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final sect = context.read<SectionProvider>();
    final state = context.read<PlayScheduleStateProvider>();

    await cloudSch.loadSchedule(widget.scheduleId);
    final schedule = cloudSch.getSchedule(widget.scheduleId)!;

    final items = schedule.items;
    state.setItems(items);

    for (var item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = schedule.playlist.versions[item.firebaseContentId]!;
          cloudVer.setVersion(item.firebaseContentId!, version);

          final sections = <String, Section>{};
          for (var entry in version.sections.entries) {
            sections[entry.key] = Section.fromFirestore(entry.value);
          }

          sect.setNewSectionsInCache(item.firebaseContentId!, sections);
          break;
        case PlaylistItemType.flowItem:
          // Flow items are loaded as part of the schedule, so no need to load separately
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Consumer6<
      PlayScheduleStateProvider,
      CloudScheduleProvider,
      PlaylistProvider,
      LocalVersionProvider,
      CipherProvider,
      FlowItemProvider
    >(
      builder: (context, state, cloudSch, play, localVer, ciph, flow, child) {
        return Stack(
          children: [
            _buildCurrentItem(cloudSch, flow, state),
            _buildCloseButton(nav),
            _buildBottomControls(state, cloudSch, localVer, ciph, flow),
          ],
        );
      },
    );
  }

  Widget _buildCurrentItem(
    CloudScheduleProvider cloudSch,
    FlowItemProvider flow,
    PlayScheduleStateProvider state,
  ) {
    final item = state.currentItem;
    if (item == null) {
      return Center(child: CircularProgressIndicator());
    }
    switch (item.type) {
      case PlaylistItemType.version:
        if (isCloud) {
          return PlayVersion(
            key: ValueKey(
              'cloud_version_${item.firebaseContentId}_${item.position}',
            ),
            cloudVersionID: item.firebaseContentId!,
          );
        } else {
          return PlayVersion(
            key: ValueKey('local_version_${item.contentId}_${item.position}'),
            localVersionID: item.contentId!,
          );
        }
      case PlaylistItemType.flowItem:
        if (isCloud) {
          final flowItemMap =
              (cloudSch.schedules[widget.scheduleId] as ScheduleDto)
                  .playlist
                  .flowItems[item.firebaseContentId]!;

          return PlayFlowItem(
            flowItem: FlowItem.fromFirestore(
              flowItemMap,
              firebaseId: item.firebaseContentId!,
              playlistId: -1,
            ),
          );
        } else {
          return PlayFlowItem(flowItem: flow.getFlowItem(item.contentId!)!);
        }
    }
  }

  Widget _buildCloseButton(NavigationProvider nav) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: () => nav.attemptPop(context),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.close, color: colorScheme.primary, size: 26),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    PlayScheduleStateProvider state,
    CloudScheduleProvider cloudSch,
    LocalVersionProvider localVer,
    CipherProvider ciph,
    FlowItemProvider flow,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(0),
          border: Border(
            top: BorderSide(color: colorScheme.surfaceContainerHigh, width: 1),
          ),
        ),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            if (state.showSettings) _buildSettingsControls(state, colorScheme),
            _buildPlayControls(
              state,
              colorScheme,
              cloudSch,
              localVer,
              ciph,
              flow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsControls(
    PlayScheduleStateProvider state,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.surfaceContainerHigh, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSettingButton(
            Icons.format_paint,
            colorScheme,
            () => _openSettingsSheet(StyleSettings(), state),
          ),
          _buildSettingButton(
            Icons.filter_alt,
            colorScheme,
            () => _openSettingsSheet(ContentFilters(), state),
          ),
          _buildSettingButton(
            Icons.auto_stories_outlined,
            colorScheme,
            () => _openSettingsSheet(AutoScrollSettings(), state),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingButton(
    IconData icon,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: colorScheme.primary),
      ),
    );
  }

  void _openSettingsSheet(Widget sheet, PlayScheduleStateProvider state) {
    state.setShowSettings(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(onClosing: () {}, builder: (context) => sheet);
      },
    );
  }

  Widget _buildPlayControls(
    PlayScheduleStateProvider state,
    ColorScheme colorScheme,
    CloudScheduleProvider cloudSch,
    LocalVersionProvider localVer,
    CipherProvider ciph,
    FlowItemProvider flow,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final currentIndex = state.currentTabIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildPreviousButton(state, colorScheme, currentIndex),
        _buildNextTitleSection(
          state,
          textTheme,
          colorScheme,
          currentIndex,
          cloudSch,
          localVer,
          ciph,
          flow,
        ),
        _buildNextButton(state, colorScheme, currentIndex),
      ],
    );
  }

  Widget _buildPreviousButton(
    PlayScheduleStateProvider state,
    ColorScheme colorScheme,
    int currentIndex,
  ) {
    return GestureDetector(
      onTap: () {
        if (currentIndex > 0) {
          final newIndex = currentIndex - 1;
          state.setCurrentTabIndex(newIndex);
          context.read<AutoScrollProvider>().clearCache();
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 48,
        child: Icon(Icons.chevron_left, color: colorScheme.primary, size: 48),
      ),
    );
  }

  Widget _buildNextTitleSection(
    PlayScheduleStateProvider state,
    TextTheme textTheme,
    ColorScheme colorScheme,
    int currentIndex,
    CloudScheduleProvider cloudSch,
    LocalVersionProvider localVer,
    CipherProvider ciph,
    FlowItemProvider flow,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2,
      child: GestureDetector(
        onTap: () => state.toggleSettings(),
        child: Builder(
          builder: (context) {
            String nextTitle = '';
            final currentItem = state.currentItem;
            if (currentItem != null &&
                state.currentTabIndex < state.itemCount - 1) {
              final nextItem = state.nextItem;
              nextTitle = _getItemTitle(
                nextItem,
                localVer,
                ciph,
                flow,
                cloudSch,
              );
            }
            return Text(
              nextTitle.isEmpty
                  ? '-'
                  : AppLocalizations.of(context)!.nextPlaceholder(nextTitle),
              style: textTheme.bodyLarge,
              softWrap: true,
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNextButton(
    PlayScheduleStateProvider state,
    ColorScheme colorScheme,
    int currentIndex,
  ) {
    return GestureDetector(
      onTap: () {
        final currentItem = state.currentItem;
        if (currentItem != null &&
            state.currentTabIndex < state.itemCount - 1) {
          final newIndex = state.currentTabIndex + 1;
          state.setCurrentTabIndex(newIndex);
          context.read<AutoScrollProvider>().clearCache();
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 48,
        child: Icon(Icons.chevron_right, color: colorScheme.primary, size: 48),
      ),
    );
  }

  /// Helper to extract title from different item types
  String _getItemTitle(
    PlaylistItem? item,
    LocalVersionProvider versionProvider,
    CipherProvider cipherProvider,
    FlowItemProvider flowItemProvider,
    CloudScheduleProvider cloudScheduleProvider,
  ) {
    if (item == null) return '';
    switch (item.type) {
      case PlaylistItemType.version:
        if (isCloud) {
          return ((cloudScheduleProvider.schedules[widget.scheduleId]
                      as ScheduleDto)
                  .playlist
                  .versions[item.firebaseContentId]
                  ?.title) ??
              '';
        } else {
          final version = versionProvider.getVersion(item.contentId!);
          if (version == null) return '';
          return cipherProvider.getCipher(version.cipherId)?.title ?? '';
        }
      case PlaylistItemType.flowItem:
        if (isCloud) {
          return ((cloudScheduleProvider.schedules[widget.scheduleId]
                      as ScheduleDto)
                  .playlist
                  .flowItems[item.firebaseContentId]?['title']) ??
              '';
        } else {
          return flowItemProvider.getFlowItem(item.contentId!)?.title ?? '';
        }
    }
  }
}
