import 'dart:async';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/widgets/schedule/play/bottom_controls.dart';
import 'package:cordis/widgets/schedule/play/flow_flex.dart';
import 'package:cordis/widgets/schedule/play/version_wrap.dart';
import 'package:flutter/material.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
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
import 'package:cordis/widgets/settings/sheet_auto_scroll.dart';
import 'package:cordis/widgets/settings/sheet_filters.dart';
import 'package:cordis/widgets/settings/sheet_style.dart';

class PlaySchedule extends StatefulWidget {
  final dynamic scheduleId;

  const PlaySchedule({super.key, required this.scheduleId});

  @override
  State<PlaySchedule> createState() => PlayScheduleState();
}

class PlayScheduleState extends State<PlaySchedule> {
  late final bool isCloud = widget.scheduleId is String;
  bool get isWide => MediaQuery.of(context).size.width > 600;

  bool _isLoading = true;

  late final PlayScheduleStateProvider _state;
  late final AutoScrollProvider _scroll;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _state = context.read<PlayScheduleStateProvider>();
    _scroll = context.read<AutoScrollProvider>();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scroll.clearCache();
      _state.reset();

      await _loadData();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _state.reset();
    _scroll.clearCache();
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

        // Sync current item
        final visibleItemIndex = _scroll.syncItemFromViewport(
          _scrollController.position.viewportDimension,
          context.read<LayoutSetProvider>().scrollDirection,
        );
        if (visibleItemIndex != null &&
            visibleItemIndex != _state.currentItemIndex) {
          _scroll.currentSectionIndex = 0;
          _state.currentItemIndex = visibleItemIndex;
          _scroll.currentItemIndex = visibleItemIndex;
        }

        // Sync current section
        _scroll.syncSectionFromViewport(
          _scrollController.position.viewportDimension,
          context.read<LayoutSetProvider>().scrollDirection,
        );
      });
    }
  }

  Future<void> _loadData() async {
    if (widget.scheduleId == null) throw Exception("Schedule ID is required");

    if (!isCloud) {
      await _loadLocal();
    } else {
      await _loadCloud();
    }
  }

  Future<void> _loadLocal() async {
    if (!mounted) return;

    final localSch = context.read<LocalScheduleProvider>();
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();
    final sect = context.read<SectionProvider>();
    final flow = context.read<FlowItemProvider>();

    final schedule = localSch.getSchedule(widget.scheduleId)!;
    await play.loadPlaylist(schedule.playlistId);

    final items = play.getPlaylist(schedule.playlistId)!.items;
    _state.setItemCount(items.length);
    for (final item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          await localVer.loadVersion(item.contentId!);
          final version = localVer.getVersion(item.contentId!);
          if (version == null) continue;
          await ciph.loadCipher(version.cipherID);
          await sect.loadSectionsOfVersion(item.contentId!);

          break;
        case PlaylistItemType.flowItem:
          await flow.loadFlowItem(item.contentId!);
          break;
      }

      _state.appendItem(item);
    }

    _scroll.currentItemIndex = 0;
  }

  Future<void> _loadCloud() async {
    if (!mounted) return;

    final cloudSch = context.read<CloudScheduleProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final sect = context.read<SectionProvider>();

    final schedule = cloudSch.getSchedule(widget.scheduleId);

    if (schedule == null) {
      throw Exception("Schedule not found");
    }

    final items = schedule.items;
    _state.setItemCount(items.length);

    for (var item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = schedule.playlist.versions[item.firebaseContentId]!;
          cloudVer.setVersion(item.firebaseContentId!, version);

          final sections = <String, Section>{};
          for (var entry in version.sections.entries) {
            sections[entry.key] = entry.value.toDomain();
          }

          sect.setNewSectionsInCache(item.firebaseContentId!, sections);
          break;
        case PlaylistItemType.flowItem:
          // Flow items are loaded as part of the schedule
          break;
      }
      // To prevent UI jank, we append items one by one with a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      _state.appendItem(item);
    }

    _scroll.currentItemIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final cloudSch = context.read<CloudScheduleProvider>();

    return Column(
      children: [
        _buildStructBar(),
        Expanded(child: _buildListView()),
        BottomControls(
          schedule: isCloud ? cloudSch.getSchedule(widget.scheduleId) : null,
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Stack(
      children: [
        Positioned.fill(
          child:
              Selector2<
                LayoutSetProvider,
                PlayScheduleStateProvider,
                (Axis, int)
              >(
                selector: (context, laySet, state) =>
                    (laySet.scrollDirection, state.itemCount),
                builder: (context, s, child) {
                  final (scrollDirection, itemCount) = s;

                  if (itemCount == 0) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.emptyPlaylist,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: scrollDirection,
                    padding: scrollDirection == Axis.vertical
                        ? const EdgeInsets.only(bottom: 16, left: 8, right: 8)
                        : const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    child: Flex(
                      direction: scrollDirection,
                      children: _buildItems(itemCount),
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

  List<Widget> _buildItems(int itemCount) {
    final items = <Widget>[];
    for (int i = 0; i < itemCount; i++) {
      final key = _scroll.registerItem(i);

      items.add(
        Container(
          key: key,
          child: Selector<PlayScheduleStateProvider, PlaylistItem?>(
            selector: (context, play) => play.getItemAt(i),
            builder: (context, item, child) {
              if (item == null) {
                return Center(child: CircularProgressIndicator());
              }

              switch (item.type) {
                case PlaylistItemType.version:
                  return VersionWrap(
                    itemIndex: i,
                    versionID: isCloud
                        ? item.firebaseContentId
                        : item.contentId,
                  );
                case PlaylistItemType.flowItem:
                  FlowItem? flow;
                  if (isCloud) {
                    flow = FlowItem.fromFirestore(
                      context
                          .read<CloudScheduleProvider>()
                          .schedules[widget.scheduleId]!
                          .playlist
                          .flowItems[item.firebaseContentId]!,
                      playlistId: -1,
                    );
                  }

                  return FlowFlex(
                    itemIndex: i,
                    flowID: item.contentId,
                    flowItem: flow,
                  );
              }
            },
          ),
        ),
      );
    }
    return items;
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

        return Column(
          children: [
            Container(
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
                      versionID: isCloud
                          ? item.firebaseContentId
                          : item.contentId,
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  if (isWide)
                    ..._buildSettingsButtons()
                  else ...[
                    Selector<PlayScheduleStateProvider, bool>(
                      selector: (_, state) => state.showSettings,
                      builder: (context, showSettings, child) {
                        return GestureDetector(
                          onTap: () {
                            _state.toggleSettings();
                          },
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              showSettings ? Icons.expand_less : Icons.tune,
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      },
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
            ),
            Selector<PlayScheduleStateProvider, bool>(
              selector: (_, state) => state.showSettings,
              builder: (context, showSettings, child) {
                if (!showSettings) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.surfaceContainerHigh,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _buildSettingsButtons(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSettingsButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      SizedBox(
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => StyleSettings(),
          ),
          child: Icon(Icons.format_paint, color: colorScheme.primary),
        ),
      ),
      SizedBox(
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => ContentFilters(),
          ),
          child: Icon(Icons.filter_alt, color: colorScheme.primary),
        ),
      ),
      SizedBox(
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AutoScrollSettings(),
          ),
          child: Icon(Icons.auto_stories_outlined, color: colorScheme.primary),
        ),
      ),
    ];
  }
}
