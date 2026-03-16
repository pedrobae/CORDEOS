import 'dart:async';
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

import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cordis/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
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
      _scroll.setPlayMode(isVertPlay: true);
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

    if (isManualScroll && _scroll.scrollModeEnabled) {
      _scroll.stopAutoScroll();
    }

    _syncCurrentSectionFromViewport();

    _syncCurrentItemFromViewport();
  }

  void _syncCurrentItemFromViewport() {
    final visibleItemIndex = _scroll.syncVerticalItemFromViewport(
      _scrollController.position.viewportDimension,
    );
    if (visibleItemIndex != null) {
      _state.setCurrentItemIndex(visibleItemIndex);
      _scroll.setActiveItemIndex(visibleItemIndex);
    }
  }

  void _syncCurrentSectionFromViewport() {
    final visibleSection = _scroll.syncVerticalSectionFromViewport(
      _scrollController.position.viewportDimension,
    );
    if (visibleSection != null) {
      _state.setCurrentItemIndex(visibleSection.itemIndex);
      _scroll.setActiveItemIndex(visibleSection.itemIndex);
    }
  }

  Future<void> _scrollToItem(int index) async {
    if (index < 0 || index >= _state.itemCount) return;

    final itemKey = _scroll.registerVerticalItem(index);
    final itemContext = itemKey.currentContext;
    if (itemContext == null || !_scrollController.hasClients) return;

    await Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0,
    );

    // Apply a fixed-pixel offset after ensureVisible so final placement does not
    // depend on item height.
    const double targetTopInset = 100;
    if (!context.mounted) return;
    final box = itemContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final itemTop = box.localToGlobal(Offset.zero).dy;
    final delta = itemTop - targetTopInset;

    if (delta.abs() < 1) return;

    final targetOffset = (currentOffset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 1),
      curve: Curves.linear,
    );

    _scroll.stopAutoScroll();
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
    _scroll.setActiveItemIndex(0);
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
    _scroll.setActiveItemIndex(0);

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
    return Stack(
      children: [
        _buildListView(),
        _buildStructBar(),
        _buildBottomControls(), // AUTO SCROLL INDICATOR
        Positioned(
          bottom: 66,
          right: 16,
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

  Widget _buildListView() {
    final scroll = context.read<AutoScrollProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Selector<PlayScheduleStateProvider, (int, bool)>(
      selector: (_, state) => (state.itemCount, state.isLoading),
      builder: (context, value, child) {
        final (itemCount, isLoading) = value;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (itemCount == 0) {
          return Center(
            child: Text(AppLocalizations.of(context)!.emptyPlaylist),
          );
        }

        final stateProvider = context.read<PlayScheduleStateProvider>();
        final items = List.generate(itemCount, (index) {
          final item = stateProvider.getItemAt(index);
          if (item == null) return const SizedBox.shrink();
          final itemKey = scroll.registerVerticalItem(index);

          switch (item.type) {
            case PlaylistItemType.version:
              return Container(
                key: itemKey,
                child: Column(
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHeader(
                        isCloud ? item.firebaseContentId : item.contentId,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionGrid(
                        index,
                        isCloud ? item.firebaseContentId : item.contentId,
                      ),
                    ),
                    Divider(color: colorScheme.primary),
                  ],
                ),
              );
            case PlaylistItemType.flowItem:
              return Container(
                key: itemKey,
                child: Consumer2<FlowItemProvider, LayoutSettingsProvider>(
                  builder: (context, flow, laySet, child) {
                    final flowItem = flow.getFlowItem(item.contentId!);

                    if (flowItem == null) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      spacing: 8,
                      children: [
                        // HEADER
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 4,
                            children: [
                              Text(
                                flowItem.title,
                                style: textTheme.titleMedium,
                              ),
                              Text(
                                '${AppLocalizations.of(context)!.estimatedTime}: ${DateTimeUtils.formatDuration(flowItem.duration)}',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(0),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: colorScheme.surfaceContainerLow,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Text(
                            flowItem.contentText,
                            style: textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              fontFamily: laySet.lyricTextStyle.fontFamily,
                            ),
                          ),
                        ),
                        Divider(color: colorScheme.primary)
                      ],
                    );
                  },
                ),
              );
          }
        });

        items.add(const SizedBox(height: 200));

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 66, bottom: 120),
          child: Column(children: items),
        );
      },
    );
  }

  Widget _buildStructBar() {
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Consumer<PlayScheduleStateProvider>(
      builder: (context, state, child) {
        final item = state.currentItem;
        if (item == null) return SizedBox.shrink();
        if (item.type == PlaylistItemType.flowItem) {
          return Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: () {
                nav.pop();
              },
              icon: Icon(Icons.close),
            ),
          );
        }

        return Positioned(
          top: 0,
          child: Container(
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
                    versionId: isCloud
                        ? item.firebaseContentId
                        : item.contentId,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    nav.pop();
                  },
                  child: Icon(Icons.close, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
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
        child: Consumer<PlayScheduleStateProvider>(
          builder: (context, state, child) {
            return Column(
              children: [
                if (state.showSettings) _buildSettingsControls(state),
                _buildPlayControls(state),
              ],
            );
          },
        ),
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
            () => _openSettingsSheet(StyleSettings(), state),
          ),
          _buildSettingsButton(
            Icons.filter_alt,
            colorScheme,
            () => _openSettingsSheet(ContentFilters(), state),
          ),
          _buildSettingsButton(
            Icons.auto_stories_outlined,
            colorScheme,
            () => _openSettingsSheet(AutoScrollSettings(), state),
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

  Widget _buildPlayControls(PlayScheduleStateProvider state) {
    final currentIndex = state.currentItemIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildPreviousButton(state, currentIndex),
        _buildNextTitleSection(currentIndex, state),
        _buildNextButton(state, currentIndex),
      ],
    );
  }

  Widget _buildPreviousButton(
    PlayScheduleStateProvider state,
    int currentIndex,
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
          Icons.keyboard_arrow_up,
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
        onTap: () => state.toggleSettings(),
        child:
            Consumer4<
              LocalVersionProvider,
              CipherProvider,
              FlowItemProvider,
              CloudScheduleProvider
            >(
              builder: (context, localVer, ciph, flow, cloudVer, child) {
                String nextTitle = '';
                final currentItem = state.currentItem;
                if (currentItem != null &&
                    state.currentItemIndex < state.itemCount - 1) {
                  final nextItem = state.nextItem;
                  nextTitle = _getItemTitle(
                    nextItem,
                    localVer,
                    ciph,
                    flow,
                    cloudVer,
                  );
                }
                return Text(
                  nextTitle.isEmpty
                      ? '-'
                      : AppLocalizations.of(
                          context,
                        )!.nextPlaceholder(nextTitle),
                  style: textTheme.bodyLarge,
                  softWrap: true,
                  textAlign: TextAlign.center,
                );
              },
            ),
      ),
    );
  }

  Widget _buildNextButton(PlayScheduleStateProvider state, int currentIndex) {
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
          Icons.keyboard_arrow_down,
          color: colorScheme.primary,
          size: 48,
        ),
      ),
    );
  }

  /// Helper to extract title from different item types
  String _getItemTitle(
    PlaylistItem? item,
    LocalVersionProvider localVer,
    CipherProvider ciph,
    FlowItemProvider flow,
    CloudScheduleProvider cloudVer,
  ) {
    if (item == null) return '';
    switch (item.type) {
      case PlaylistItemType.version:
        if (isCloud) {
          return ((cloudVer.schedules[widget.scheduleId] as ScheduleDto)
                  .playlist
                  .versions[item.firebaseContentId]
                  ?.title) ??
              '';
        } else {
          final version = localVer.getVersion(item.contentId!);
          if (version == null) return '';
          return ciph.getCipher(version.cipherId)?.title ?? '';
        }
      case PlaylistItemType.flowItem:
        if (isCloud) {
          return ((cloudVer.schedules[widget.scheduleId] as ScheduleDto)
                  .playlist
                  .flowItems[item.firebaseContentId]?['title']) ??
              '';
        } else {
          return flow.getFlowItem(item.contentId!)?.title ?? '';
        }
    }
  }

  Widget _buildSectionGrid(int itemIndex, dynamic versionId) {
    return Consumer4<
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      LayoutSettingsProvider
    >(
      builder: (context, localVer, cloudVer, sect, laySet, child) {
        List<String> songStructure;
        if (isCloud) {
          final version = cloudVer.getVersion(versionId);
          if (version == null) {
            return const Center(child: CircularProgressIndicator());
          }
          songStructure = version.songStructure;
        } else {
          final version = localVer.getVersion(versionId);
          if (version == null) {
            return const Center(child: CircularProgressIndicator());
          }
          songStructure = version.songStructure;
        }

        final filteredStructure = songStructure
            .where(
              (sectionCode) =>
                  ((laySet.layoutFilters[LayoutFilter.annotations]! ||
                      !isAnnotation(sectionCode)) &&
                  (laySet.layoutFilters[LayoutFilter.transitions]! ||
                      !isTransition(sectionCode))),
            )
            .toList();

        final scroll = context.read<AutoScrollProvider>();

        for (var i = 0; i < filteredStructure.length; i++) {
          scroll.registerVerticalSection(itemIndex, i);
        }

        return MasonryGridView.count(
          crossAxisCount: laySet.columnCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: filteredStructure.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final trimmedCode = filteredStructure[index].trim();
            final sectionKey = scroll.registerVerticalSection(itemIndex, index);
            final section = isCloud
                ? () {
                    final sectionMap = cloudVer
                        .getVersion(versionId)!
                        .sections[trimmedCode]!;
                    return Section.fromFirestore(sectionMap);
                  }()
                : sect.getSection(versionId, trimmedCode);

            if (section == null) {
              return const SizedBox.shrink();
            }

            scroll.setVerticalSectionLineCount(
              itemIndex,
              index,
              section.contentText.split('\n').length,
            );

            if (isAnnotation(trimmedCode)) {
              return AnnotationCard(
                key: sectionKey,
                sectionText: section.contentText,
                sectionType: section.contentType,
              );
            }

            return SectionCard(
              key: sectionKey,
              sectionType: section.contentType,
              sectionCode: trimmedCode,
              sectionText: section.contentText,
              sectionColor: section.contentColor,
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(dynamic versionID) {
    return Consumer3<
      LocalVersionProvider,
      CloudVersionProvider,
      CipherProvider
    >(
      builder: (context, localVer, cloudVer, ciph, child) {
        final textTheme = Theme.of(context).textTheme;

        String title;
        String key;
        int bpm;
        Duration duration;

        if (isCloud) {
          final version = cloudVer.getVersion(versionID);
          if (version == null) return const LinearProgressIndicator();
          title = version.title;
          key = version.transposedKey ?? version.originalKey;
          bpm = version.bpm;
          duration = Duration(milliseconds: version.duration);
        } else {
          final version = localVer.getVersion(versionID);
          if (version == null) return const LinearProgressIndicator();
          final cipher = ciph.getCipher(version.cipherId);
          if (cipher == null) return const LinearProgressIndicator();
          title = cipher.title;
          key = version.transposedKey ?? cipher.musicKey;
          bpm = version.bpm;
          duration = version.duration;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            Text(title, style: textTheme.titleMedium),
            Row(
              spacing: 16.0,
              children: [
                Text(
                  AppLocalizations.of(context)!.keyWithPlaceholder(key),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  AppLocalizations.of(context)!.bpmWithPlaceholder(bpm),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(duration)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
