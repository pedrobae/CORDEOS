import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/providers/auto_scroll_provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/schedule/play_schedule_state_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomControls extends StatefulWidget {
  final PlaylistDto? playlistDto;

  const BottomControls({super.key, this.playlistDto});

  @override
  State<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<BottomControls> {
  late final PlayScheduleStateProvider _state;
  late final AutoScrollProvider _scroll;

  @override
  void initState() {
    super.initState();
    _state = context.read<PlayScheduleStateProvider>();
    _scroll = context.read<AutoScrollProvider>();
  }

  Future<void> _scrollToItem(int index) async {
    if (index < 0 || index >= _state.itemCount) return;
    final itemKey = _scroll.registerItem(index);
    final itemContext = itemKey.currentContext;
    if (itemContext == null) return;

    _state.currentItemIndex = index;

    await Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0,
    );

    _scroll.stopAutoScroll();
    _scroll.currentSectionIndex = 0;
    _scroll.currentItemIndex = index;
  }

  @override
  Widget build(BuildContext context) {
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
      child:
          Selector2<
            PlayScheduleStateProvider,
            LayoutSetProvider,
            ({int currentIndex, Axis scrollDirection, int itemCount})
          >(
            selector: (_, playState, layoutState) => (
              currentIndex: playState.currentItemIndex,
              scrollDirection: layoutState.scrollDirection,
              itemCount: playState.itemCount,
            ),
            builder: (context, s, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildPreviousButton(s.currentIndex, s.scrollDirection),
                  _buildNextTitleSection(s.currentIndex, s.itemCount),
                  _buildNextButton(
                    s.currentIndex,
                    s.scrollDirection,
                    s.itemCount,
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildPreviousButton(int currentIndex, Axis scrollDirection) {
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

  Widget _buildNextButton(
    int currentIndex,
    Axis scrollDirection,
    int itemCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (currentIndex < itemCount - 1) {
          _scrollToItem(currentIndex + 1);
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

  Widget _buildNextTitleSection(int currentIndex, int itemCount) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: MediaQuery.of(context).size.width / 2,
      child: Selector<PlayScheduleStateProvider, PlaylistItem?>(
        selector: (_, s) => s.nextItem,
        builder: (context, nextItem, child) {
          String nextTitle = '';
          if (currentIndex < itemCount - 1 && nextItem != null) {
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
    );
  }

  String _getItemTitle(PlaylistItem item) {
    switch (item.type) {
      case PlaylistItemType.version:
        if (widget.playlistDto == null) {
          final localVer = context.read<LocalVersionProvider>();
          final ciph = context.read<CipherProvider>();
          if (item.contentId == null) return '';
          final version = localVer.getVersion(item.contentId!);
          if (version == null) return '';
          return ciph.getCipher(version.cipherID)?.title ?? '';
        } else {
          return (widget
                  .playlistDto!
                  .versions[item.firebaseContentId]
                  ?.title) ??
              '';
        }
      case PlaylistItemType.flowItem:
        if (widget.playlistDto == null) {
          final flow = context.read<FlowItemProvider>();
          if (item.contentId == null) return '';
          return flow.getFlowItem(item.contentId!)?.title ?? '';
        } else {
          return (widget.playlistDto!.flowItems[item
                  .firebaseContentId]?['title']) ??
              '';
        }
    }
  }
}
