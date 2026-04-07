import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/providers/playlist/auto_scroll_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/play_state_provider.dart';
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

  late final ScrollController _scrollController;
  late final PlayStateProvider _state;
  late final ScrollProvider _scroll;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _state = context.read<PlayStateProvider>();
    _scroll = context.read<ScrollProvider>();
    _scroll.setScrollController(_scrollController);

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

      if (!mounted || !_scrollController.hasClients) return;

      _syncFromViewPort();
    }
  }

  void _syncFromViewPort() {
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
  }

  void _scrollOneStep({required bool forward}) async {
    if (!_scrollController.hasClients) return;
    final laySet = context.read<LayoutSetProvider>();
    if (laySet.scrollDirection == Axis.vertical) {
      // VERTICAL: use provider to calculate next item index and scroll to it
      _scroll.scrollToNextSection(forward: forward);
      if (_scroll.currentItemIndex != _state.currentItemIndex) {
        _state.currentItemIndex = _scroll.currentItemIndex;
      }
    } else {
      // HORIZONTAL: calculate scroll offset based on card width (always constant)
      final width = MediaQuery.of(context).size.width;
      final scrollAmount =
          width * laySet.cardWidthMult + 8; // card width + padding
      final targetOffset = forward
          ? _scrollController.offset + scrollAmount
          : _scrollController.offset - scrollAmount;
      await _scrollController.animateTo(
        targetOffset.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _syncFromViewPort();
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
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        Positioned.fill(
          child: Selector2<LayoutSetProvider, PlayStateProvider, (Axis, int)>(
            selector: (context, laySet, state) =>
                (laySet.scrollDirection, state.itemCount),
            builder: (context, s, child) {
              final (scrollDirection, itemCount) = s;

              if (itemCount == 0) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.emptyPlaylist,
                    style: textTheme.bodyLarge,
                  ),
                );
              }

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: scrollDirection,
                child: Flex(
                  direction: scrollDirection,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < itemCount; i++) ...[
                      Padding(
                        padding: scrollDirection == Axis.vertical
                            ? const EdgeInsets.symmetric(horizontal: 8)
                            : const EdgeInsets.symmetric(vertical: 8),
                        child: _buildItem(i, scrollDirection),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        // auto scroll indicator
        Positioned(
          bottom: 8,
          right: 8,
          child: Selector<ScrollProvider, bool>(
            selector: (context, scrollProvider) =>
                scrollProvider.scrollModeEnabled,
            builder: (context, scrollModeEnabled, _) {
              return Visibility(
                visible: scrollModeEnabled,
                maintainState: true,
                child: AutoScrollIndicator(),
              );
            },
          ),
        ),

        // invisible large scroll button overlays that only absorb tap events
        _buildTransparentButtons(),
      ],
    );
  }

  Widget _buildItem(int i, Axis scrollDirection) {
    final key = _scroll.registerItem(i);

    return Container(
      key: key,
      child: Selector<PlayStateProvider, PlaylistItem?>(
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
    );
  }

  Widget _buildTransparentButtons() {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector3<
      ScrollProvider,
      LayoutSetProvider,
      PlayStateProvider,
      ({bool transparentButtons, bool isVertical, bool showButtons})
    >(
      selector: (context, scroll, laySet, playState) => (
        transparentButtons: scroll.transparentButtons,
        isVertical: laySet.scrollDirection == Axis.vertical,
        showButtons: playState.showButtons,
      ),
      builder: (context, s, _) {
        if (!s.transparentButtons) {
          return Positioned(top: 0, left: 0, child: SizedBox.shrink());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            const buttonSpacing = 16.0;
            final effectiveWidth = constraints.maxWidth - buttonSpacing;
            final effectiveHeight = constraints.maxHeight - buttonSpacing;
            final halfWidth = effectiveWidth / 2;
            final halfHeight = effectiveHeight / 2;
            return Flex(
              spacing: buttonSpacing,
              direction: s.isVertical ? Axis.vertical : Axis.horizontal,
              children: [
                // Back/Up button area
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _scrollOneStep(forward: false);
                  },
                  child: Container(
                    decoration: s.showButtons
                        ? BoxDecoration(
                            color: colorScheme.surfaceTint.withAlpha(63),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    width: s.isVertical ? constraints.maxWidth : halfWidth,
                    height: s.isVertical ? halfHeight : constraints.maxHeight,
                    child: s.showButtons
                        ? Icon(
                            s.isVertical
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_back_rounded,
                            color: colorScheme.primary.withAlpha(127),
                            size: 80,
                          )
                        : null,
                  ),
                ),
                // Forward/Down button area
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _scrollOneStep(forward: true);
                  },
                  child: Container(
                    decoration: s.showButtons
                        ? BoxDecoration(
                            color: colorScheme.surfaceTint.withAlpha(127),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    width: s.isVertical ? constraints.maxWidth : halfWidth,
                    height: s.isVertical ? halfHeight : constraints.maxHeight,
                    child: s.showButtons
                        ? Icon(
                            s.isVertical
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_forward_rounded,
                            color: colorScheme.primary.withAlpha(127),
                            size: 80,
                          )
                        : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStructBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final nav = context.read<NavigationProvider>();
    return Selector<PlayStateProvider, PlaylistItem?>(
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
                    Selector<PlayStateProvider, bool>(
                      selector: (_, state) => state.showSettings,
                      builder: (context, showSettings, child) {
                        return GestureDetector(
                          onTap: () => _state.toggleSettings(),
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
            Selector<PlayStateProvider, bool>(
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
          builder: (context) => StyleSettings(secret: true),
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
              return ManageSheet(versionID: _state.currentItem!.contentId!);
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

      for (var item in _state.items) {
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
