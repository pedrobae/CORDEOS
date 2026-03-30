import 'dart:async';

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/providers/auto_scroll_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/schedule/play_schedule_state_provider.dart';
import 'package:cordeos/providers/section_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/sheet_manage.dart';
import 'package:cordeos/widgets/ciphers/viewer/structure_list.dart';
import 'package:cordeos/widgets/play/auto_scroll_indicator.dart';
import 'package:cordeos/widgets/play/bottom_controls.dart';
import 'package:cordeos/widgets/play/flow_flex.dart';
import 'package:cordeos/widgets/play/version_wrap.dart';
import 'package:cordeos/widgets/settings/sheet_auto_scroll.dart';
import 'package:cordeos/widgets/settings/sheet_filters.dart';
import 'package:cordeos/widgets/settings/sheet_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// Used to play a playlist, assumes the providers are loaded.
class PlayPlaylist extends StatefulWidget {
  final PlaylistDto? playlistDto;
  final bool canEdit;

  const PlayPlaylist({super.key, this.playlistDto, this.canEdit = false});

  @override
  State<PlayPlaylist> createState() => _PlayPlaylistState();
}

class _PlayPlaylistState extends State<PlayPlaylist> {
  bool get isWide => MediaQuery.of(context).size.width > 600;
  bool _isLoading = true;

  late Timer? _listenerThrottle;

  late final ScrollController _scrollController;
  late final PlayScheduleStateProvider _play;
  late final AutoScrollProvider _scroll;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _listenerThrottle = null;

    _play = context.read<PlayScheduleStateProvider>();
    _scroll = context.read<AutoScrollProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scroll.clearCache();

      setState(() {
        _isLoading = false;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _listenerThrottle?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _play.reset();
    _scroll.clearCache();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final isManualScroll =
        _scrollController.position.userScrollDirection != ScrollDirection.idle;

    if (isManualScroll) {
      if (_scroll.scrollModeEnabled) _scroll.stopAutoScroll();

      _listenerThrottle?.cancel();
      _listenerThrottle = Timer(const Duration(milliseconds: 200), () {
        if (!mounted || !_scrollController.hasClients) return;

        // Sync current item
        final visibleItemIndex = _scroll.syncItemFromViewport(
          _scrollController.position.viewportDimension,
          context.read<LayoutSetProvider>().scrollDirection,
        );
        if (visibleItemIndex != null &&
            visibleItemIndex != _play.currentItemIndex) {
          _scroll.currentSectionIndex = 0;
          _play.currentItemIndex = visibleItemIndex;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStructBar(),
        Expanded(child: _buildListView()),
        BottomControls(playlistDto: widget.playlistDto),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    versionID: widget.playlistDto != null
                        ? item.firebaseContentId
                        : item.contentId,
                  );
                case PlaylistItemType.flowItem:
                  FlowItem? flow;
                  if (widget.playlistDto != null) {
                    flow = FlowItem.fromFirestore(
                      widget.playlistDto!.flowItems[item.firebaseContentId]!,
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
        final isFlow = item.type == PlaylistItemType.flowItem;

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
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  // back button (edit only)
                  if (widget.canEdit)
                    GestureDetector(
                      onTap: () => nav.attemptPop(context),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  // Structure (version only)
                  Expanded(
                    child: isFlow
                        ? SizedBox()
                        : StructureList(
                            versionID: widget.playlistDto != null
                                ? item.firebaseContentId
                                : item.contentId,
                          ),
                  ),

                  // Loading indicator
                  if (_isLoading)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),

                  // Settings buttons (wide only)
                  if (isWide) ..._buildSettingsButtons(),

                  // settings toggle (narrow, view only)
                  if (!isWide && !widget.canEdit)
                    Selector<PlayScheduleStateProvider, bool>(
                      selector: (_, state) => state.showSettings,
                      builder: (context, showSettings, child) {
                        return GestureDetector(
                          onTap: () => _play.toggleSettings(),
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

                  // Save button (edit only)
                  if (widget.canEdit)
                    GestureDetector(
                      onTap: _handleSave,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.save, color: colorScheme.primary),
                      ),
                    ),

                  // Close button (view only)
                  if (!widget.canEdit)
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
                if (!showSettings && !widget.canEdit) {
                  return const SizedBox.shrink();
                }
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
      GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => StyleSettings(),
        ),
        onLongPress: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => StyleSettings(secret: true,),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.format_paint, color: colorScheme.primary),
        ),
      ),
      GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => ContentFilters(),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.filter_alt, color: colorScheme.primary),
        ),
      ),
      if (widget.canEdit)
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            builder: (context) {
              return ManageSheet(versionID: _play.currentItem!.contentId!);
            },
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.edit, color: colorScheme.primary),
          ),
        ),
      if (!widget.canEdit)
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AutoScrollSettings(),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.auto_stories_outlined,
              color: colorScheme.primary,
            ),
          ),
        ),
    ];
  }

  VoidCallback _handleSave() {
    return () {
      final localVer = context.read<LocalVersionProvider>();
      final sect = context.read<SectionProvider>();
      final nav = context.read<NavigationProvider>();

      for (var item in _play.items) {
        switch (item.type) {
          case PlaylistItemType.version:
            // Save version changes
            localVer.saveVersion(versionID: item.contentId!);
            sect.saveSections(versionID: item.contentId!);
            break;
          case PlaylistItemType.flowItem:
            // Cant edit flow items from here, only manage version maps
            break;
        }
      }
      nav.pop();
    };
  }
}
