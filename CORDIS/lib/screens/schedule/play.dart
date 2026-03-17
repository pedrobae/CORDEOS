import 'dart:async';
import 'package:cordis/widgets/schedule/play/content_wrap.dart';
import 'package:flutter/material.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/dtos/schedule_dto.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';

import 'package:flutter/rendering.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:cordis/widgets/schedule/play/auto_scroll_indicator.dart';
import 'package:cordis/widgets/settings/auto_scroll_settings.dart';
import 'package:cordis/widgets/settings/content_filters.dart';
import 'package:cordis/widgets/settings/style_settings.dart';

class VertPlaySchedule extends StatefulWidget {
  final dynamic scheduleId;

  const VertPlaySchedule({super.key, required this.scheduleId});

  @override
  State<VertPlaySchedule> createState() => VertPlayScheduleState();
}

class VertPlayScheduleState extends State<VertPlaySchedule> {
  late final bool isCloud = widget.scheduleId is String;
  late final bool isWide = MediaQuery.of(context).size.width > 600;

  late final PlayScheduleStateProvider _state;
  late final AutoScrollProvider _scroll;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _state = context.read<PlayScheduleStateProvider>();
    _scroll = context.read<AutoScrollProvider>();

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scroll.clearCache();
      _state.reset();

      _loadData();
      _scrollController.addListener(_scrollListener);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final isManualScroll =
        _scrollController.position.userScrollDirection != ScrollDirection.idle;

    if (isManualScroll) {
      if (_scroll.scrollModeEnabled) _scroll.stopAutoScroll();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _syncItemFromViewport();
        _syncSectionFromViewport();
      });
    }
  }

  void _syncItemFromViewport() {
    final visibleItemIndex = _scroll.syncItemFromViewport(
      _scrollController.position.viewportDimension,
      context.read<LayoutSettingsProvider>().scrollDirection,
    );
    if (visibleItemIndex != null) {
      _state.currentItemIndex = visibleItemIndex;
      _scroll.currentItemIndex = visibleItemIndex;
    }
  }

  void _syncSectionFromViewport() {
    _scroll.syncSectionFromViewport(
      _scrollController.position.viewportDimension,
      context.read<LayoutSettingsProvider>().scrollDirection,
    );
  }

  Future<void> _scrollToItem(int index) async {
    if (index < 0 || index >= _state.itemCount) return;
    final itemKey = _scroll.registerItem(index);
    final itemContext = itemKey.currentContext;
    if (itemContext == null || !_scrollController.hasClients) return;

    await Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0,
    );

    _scroll.stopAutoScroll();
    _scroll.currentSectionIndex =
        0; // Reset section index when manually changing item
    _scroll.currentItemIndex = index;
    _state.currentItemIndex = index;
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
    final flow = context.read<FlowItemProvider>();

    final schedule = scheduleProvider.getSchedule(widget.scheduleId)!;
    await playlistProvider.loadPlaylist(schedule.playlistId);

    final items = playlistProvider.getPlaylist(schedule.playlistId)!.items;
    _state.setItems(items);
    _scroll.currentItemIndex = 0;
    for (final item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          await _loadLocalVersion(item);
          break;
        case PlaylistItemType.flowItem:
          await flow.loadFlowItem(item.contentId!);
          break;
      }
    }
  }

  Future<void> _loadLocalVersion(PlaylistItem item) async {
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();
    final sect = context.read<SectionProvider>();

    await localVer.loadVersion(item.contentId!);
    final version = localVer.getVersion(item.contentId!)!;
    await ciph.loadCipher(version.cipherId);
    await sect.loadSectionsOfVersion(item.contentId!);
  }

  Future<void> _loadCloud() async {
    final cloudSch = context.read<CloudScheduleProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final sect = context.read<SectionProvider>();

    await cloudSch.loadSchedule(widget.scheduleId);
    final schedule = cloudSch.getSchedule(widget.scheduleId)!;

    final items = schedule.items;
    _state.setItems(items);
    _scroll.currentItemIndex = 0;

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
          // Flow items are loaded as part of the schedule
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStructBar(),
        Expanded(child: _buildListView()),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildListView() {
    return Stack(
      children: [
        Positioned.fill(
          child: Selector<LayoutSettingsProvider, Axis>(
            selector: (context, laySet) => laySet.scrollDirection,
            builder: (context, scrollDirection, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: scrollDirection,
                  child: ContentWrap(isCloud: isCloud),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Consumer<AutoScrollProvider>(
            builder: (context, scrollProvider, _) {
              return Visibility(
                visible: scrollProvider.scrollModeEnabled,
                maintainState: true,
                child: AutoScrollIndicator(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStructBar() {
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector<PlayScheduleStateProvider, PlaylistItem?>(
      selector: (_, state) => state.currentItem,
      builder: (context, item, child) {
        if (item == null) return const SizedBox.shrink();
        if (item.type == PlaylistItemType.flowItem) {
          return Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                nav.pop();
              },
              icon: const Icon(Icons.close),
            ),
          );
        }

        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
              bottom: BorderSide(
                color: colorScheme.surfaceContainerHigh,
                width: 1,
              ),
            ),
            color: colorScheme.surface,
          ),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: StructureList(
                  versionId: isCloud ? item.firebaseContentId : item.contentId,
                ),
              ),
              if (isWide) ...[
                /// Show setting button on wide screens
                _buildSettingsButton(
                  Icons.format_paint,
                  colorScheme,
                  () => _openSettingsSheet(StyleSettings()),
                ),
                _buildSettingsButton(
                  Icons.filter_alt,
                  colorScheme,
                  () => _openSettingsSheet(ContentFilters()),
                ),
                _buildSettingsButton(
                  Icons.auto_stories_outlined,
                  colorScheme,
                  () => _openSettingsSheet(AutoScrollSettings()),
                ),
              ],
              GestureDetector(
                onTap: () {
                  nav.pop();
                },
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.close, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
        border: Border(
          top: BorderSide(color: colorScheme.surfaceContainerHigh, width: 1),
        ),
      ),
      width: MediaQuery.of(context).size.width,
      child: Selector<PlayScheduleStateProvider, bool>(
        selector: (_, state) => state.showSettings,
        builder: (context, showSettings, child) {
          final state = context.read<PlayScheduleStateProvider>();
          return Column(
            children: [
              if (showSettings) _buildSettingsControls(state),
              _buildPlayControls(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsControls(PlayScheduleStateProvider state) {
    final colorScheme = Theme.of(context).colorScheme;

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
          _buildSettingsButton(
            Icons.format_paint,
            colorScheme,
            () => _openSettingsSheet(StyleSettings(), state: state),
          ),
          _buildSettingsButton(
            Icons.filter_alt,
            colorScheme,
            () => _openSettingsSheet(ContentFilters(), state: state),
          ),
          _buildSettingsButton(
            Icons.auto_stories_outlined,
            colorScheme,
            () => _openSettingsSheet(AutoScrollSettings(), state: state),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(
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

  void _openSettingsSheet(Widget sheet, {PlayScheduleStateProvider? state}) {
    if (state != null && !isWide) state.setShowSettings(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => sheet,
    );
  }

  Widget _buildPlayControls(PlayScheduleStateProvider state) {
    return Selector2<
      PlayScheduleStateProvider,
      LayoutSettingsProvider,
      (int, Axis)
    >(
      selector: (_, playState, layoutState) =>
          (playState.currentItemIndex, layoutState.scrollDirection),
      builder: (context, value, child) {
        final (currentIndex, scrollDirection) = value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildPreviousButton(state, currentIndex, scrollDirection),
            _buildNextTitleSection(currentIndex, state),
            _buildNextButton(state, currentIndex, scrollDirection),
          ],
        );
      },
    );
  }

  Widget _buildPreviousButton(
    PlayScheduleStateProvider state,
    int currentIndex,
    Axis scrollDirection,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (currentIndex > 0) {
          _scrollToItem(currentIndex - 1);
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 48,
        child: Icon(
          scrollDirection == Axis.vertical
              ? Icons.keyboard_arrow_up
              : Icons.keyboard_arrow_left,
          color: colorScheme.primary,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildNextTitleSection(
    int currentIndex,
    PlayScheduleStateProvider state,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: MediaQuery.of(context).size.width / 2,
      child: GestureDetector(
        onTap: () {
          if (!isWide) state.toggleSettings();
        },
        child: Selector<PlayScheduleStateProvider, PlaylistItem?>(
          selector: (_, s) => s.nextItem,
          builder: (context, nextItem, child) {
            String nextTitle = '-';
            if (currentIndex < state.itemCount - 1 && nextItem != null) {
              nextTitle = _getItemTitle(nextItem);
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
    int currentIndex,
    Axis scrollDirection,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        final currentItem = state.currentItem;
        if (currentItem != null &&
            state.currentItemIndex < state.itemCount - 1) {
          _scrollToItem(state.currentItemIndex + 1);
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 48,
        child: Icon(
          scrollDirection == Axis.vertical
              ? Icons.keyboard_arrow_down
              : Icons.keyboard_arrow_right,
          color: colorScheme.primary,
          size: 48,
        ),
      ),
    );
  }

  /// Helper to extract title from different item types
  String _getItemTitle(PlaylistItem item) {
    switch (item.type) {
      case PlaylistItemType.version:
        if (isCloud) {
          final cloudVer = context.read<CloudScheduleProvider>();
          return ((cloudVer.schedules[widget.scheduleId] as ScheduleDto)
                  .playlist
                  .versions[item.firebaseContentId]
                  ?.title) ??
              '';
        } else {
          final localVer = context.read<LocalVersionProvider>();
          final ciph = context.read<CipherProvider>();
          final version = localVer.getVersion(item.contentId!);
          if (version == null) return '';
          return ciph.getCipher(version.cipherId)?.title ?? '';
        }
      case PlaylistItemType.flowItem:
        if (isCloud) {
          final cloudVer = context.read<CloudScheduleProvider>();
          return ((cloudVer.schedules[widget.scheduleId] as ScheduleDto)
                  .playlist
                  .flowItems[item.firebaseContentId]?['title']) ??
              '';
        } else {
          final flow = context.read<FlowItemProvider>();
          return flow.getFlowItem(item.contentId!)?.title ?? '';
        }
    }
  }
}
