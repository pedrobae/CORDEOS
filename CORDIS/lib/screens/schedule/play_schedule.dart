import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';

import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

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
  List<PlaylistItem> items = [];
  late PlayScheduleStateProvider _stateProvider;

  @override
  void initState() {
    super.initState();
    _stateProvider = context.read<PlayScheduleStateProvider>();
    _stateProvider.reset();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializePlaylist();
      await _loadItemsAroundCurrent(0);
    });
  }

  /// Load only the current playlist structure without full content
  Future<void> _initializePlaylist() async {
    final scheduleProvider = context.read<LocalScheduleProvider>();
    final cloudScheduleProvider = context.read<CloudScheduleProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    if (widget.scheduleId == null) throw Exception("Schedule ID is required");

    if (!isCloud) {
      final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;
      await playlistProvider.loadPlaylist(schedule.playlistId!);
      if (mounted) {
        setState(() {
          items = playlistProvider.getPlaylistById(schedule.playlistId!)!.items;
        });
      }
    } else {
      if (!cloudScheduleProvider.schedules.containsKey(widget.scheduleId)) {
        await cloudScheduleProvider.loadSchedule(widget.scheduleId);
      }

      final schedule = cloudScheduleProvider.schedules[widget.scheduleId];
      if (schedule == null) {
        throw Exception("Schedule not found");
      }
      if (mounted) {
        setState(() {
          items = schedule.playlist.getPlaylistItems();
        });
      }
    }
  }

  /// Lazy load data for current
  /// This dramatically reduces initial load time and memory usage
  Future<void> _loadItemsAroundCurrent(int currentIndex) async {
    if (isCloud) return; // Cloud items are loaded on with scheduleDTO
    final versionProvider = context.read<LocalVersionProvider>();
    final cipherProvider = context.read<CipherProvider>();
    final flowItemProvider = context.read<FlowItemProvider>();
    final sectionProvider = context.read<SectionProvider>();

    // Load current, previous, and next items
    const int loadRadius = 1;
    final indicesToLoad = <int>{};
    indicesToLoad.add(currentIndex);
    for (int i = 1; i <= loadRadius; i++) {
      if (currentIndex - i >= 0) indicesToLoad.add(currentIndex - i);
      if (currentIndex + i < items.length) indicesToLoad.add(currentIndex + i);
    }

    for (final idx in indicesToLoad) {
      final item = items[idx];

      if (item.type == PlaylistItemType.version) {
        // Skip if already loaded
        if (versionProvider.cachedVersion(item.contentId!) != null) continue;

        await versionProvider.loadVersion(item.contentId!);
        await cipherProvider.loadCipherOfVersion(item.contentId!);
        await sectionProvider.loadSectionsOfVersion(item.contentId!);
      } else if (item.type == PlaylistItemType.flowItem) {
        // Skip if already loaded
        if (flowItemProvider.getFlowItem(item.contentId!) != null) continue;

        await flowItemProvider.loadFlowItem(item.contentId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            _buildTabViewer(state, cloudSch, play, localVer, ciph, flow),
            _buildCloseButton(nav, colorScheme),
            _buildBottomControls(state, colorScheme, cloudSch, localVer, ciph, flow),
          ],
        );
      },
    );
  }

  Widget _buildTabViewer(
    PlayScheduleStateProvider state,
    CloudScheduleProvider cloudSch,
    PlaylistProvider play,
    LocalVersionProvider localVer,
    CipherProvider ciph,
    FlowItemProvider flow,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return _buildLoadingOrEmptyState(localVer, cloudSch, flow, ciph, play, colorScheme, textTheme);
    }

    return Builder(
      builder: (context) {
        return _buildCurrentItem(state.currentTabIndex, cloudSch, flow);
      },
    );
  }

  Widget _buildLoadingOrEmptyState(
    LocalVersionProvider localVer,
    CloudScheduleProvider cloudSch,
    FlowItemProvider flow,
    CipherProvider ciph,
    PlaylistProvider play,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (localVer.isLoading || cloudSch.isLoading || flow.isLoading || ciph.isLoading || play.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    return Center(
      child: Text(
        AppLocalizations.of(context)!.noPlaylistItems,
        style: textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildCurrentItem(int currentTabIndex, CloudScheduleProvider cloudSch, FlowItemProvider flow) {
    final item = items[currentTabIndex];
    switch (item.type) {
      case PlaylistItemType.version:
        if (isCloud) {
          return PlayVersion(cloudVersionID: item.firebaseContentId!);
        } else {
          return PlayVersion(localVersionID: item.contentId!);
        }
      case PlaylistItemType.flowItem:
        if (isCloud) {
          final flowItemMap = (cloudSch.schedules[widget.scheduleId] as ScheduleDto)
              .playlist
              .flowItems[item.firebaseContentId]!;

          return PlayFlowItem(
            flowItem: FlowItem(
              firebaseId: item.firebaseContentId!,
              playlistId: -1,
              title: flowItemMap['title'] as String,
              contentText: flowItemMap['contentText'] as String,
              duration: Duration(seconds: (flowItemMap['duration'] as int)),
              position: flowItemMap['position'] as int,
            ),
          );
        } else {
          return PlayFlowItem(flowItem: flow.getFlowItem(item.contentId!)!);
        }
    }
  }

  Widget _buildCloseButton(NavigationProvider nav, ColorScheme colorScheme) {
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
    ColorScheme colorScheme,
    CloudScheduleProvider cloudSch,
    LocalVersionProvider localVer,
    CipherProvider ciph,
    FlowItemProvider flow,
  ) {
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
            if (state.showSettings)
              _buildSettingsControls(state, colorScheme),
            _buildPlayControls(state, colorScheme, cloudSch, localVer, ciph, flow),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsControls(PlayScheduleStateProvider state, ColorScheme colorScheme) {
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
        return BottomSheet(
          onClosing: () {},
          builder: (context) => sheet,
        );
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
          _loadItemsAroundCurrent(newIndex);
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
            if (currentIndex < items.length - 1) {
              final nextItem = items[currentIndex + 1];
              nextTitle = _getItemTitle(nextItem, localVer, ciph, flow, cloudSch);
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
        if (currentIndex < items.length - 1) {
          final newIndex = currentIndex + 1;
          state.setCurrentTabIndex(newIndex);
          _loadItemsAroundCurrent(newIndex);
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
    PlaylistItem item,
    LocalVersionProvider versionProvider,
    CipherProvider cipherProvider,
    FlowItemProvider flowItemProvider,
    CloudScheduleProvider cloudScheduleProvider,
  ) {
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
          final version = versionProvider.cachedVersion(item.contentId!);
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
