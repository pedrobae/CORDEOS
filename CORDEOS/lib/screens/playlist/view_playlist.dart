import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';

import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/play/play_state_provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';

import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/play/play_playlist.dart';
import 'package:cordeos/services/sync_service.dart';

import 'package:cordeos/widgets/playlist/viewer/add_to_playlist_sheet.dart';

import 'package:cordeos/widgets/playlist/viewer/version_card.dart';
import 'package:cordeos/widgets/playlist/viewer/flow_item_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewPlaylistScreen extends StatefulWidget {
  final PlaylistDto? playlistDto;
  final int playlistID;
  final bool canEdit;
  final bool isPadded;

  const ViewPlaylistScreen({
    super.key,
    required this.playlistID,
    this.playlistDto,
    this.canEdit = false,
    this.isPadded = false,
  });

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector<
      PlaylistProvider,
      ({String name, List<PlaylistItem> items})
    >(
      selector: (context, play) {
        final playlist = play.getPlaylist(widget.playlistID);

        return (
          name:
              (widget.playlistDto == null
                  ? playlist?.name
                  : widget.playlistDto?.name) ??
              '',
          items:
              (widget.playlistDto == null
                  ? playlist?.items
                  : widget.playlistDto?.toDomain(-1).items) ??
              [],
        );
      },
      builder: (context, s, child) {
        if (s.name.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: widget.isPadded
              ? AppBar(
                  leading: BackButton(
                    color: colorScheme.onSurface,
                    onPressed: () => nav.attemptPop(context),
                  ),
                  title: Text(s.name, style: textTheme.titleMedium),
                  actions: widget.canEdit
                      ? [
                          // Play
                          IconButton(
                            icon: Icon(
                              Icons.play_circle_fill_rounded,
                              color: colorScheme.onSurface,
                              size: 30,
                            ),
                            onPressed: () {
                              final localVer = context
                                  .read<LocalVersionProvider>();
                              final sect = context.read<SectionProvider>();
                              final state = context.read<PlayStateProvider>();
                              final scroll = context.read<ScrollProvider>();

                              scroll.disableAutoScrollMode();
                              state.setItemCount(s.items.length);
                              for (var item in s.items) {
                                state.appendItem(item);
                              }

                              nav.push(
                                () => PlayPlaylist(canEdit: true),
                                changeDetector: () {
                                  return localVer.hasUnsavedChanges ||
                                      sect.hasUnsavedChanges;
                                },
                                onChangeDiscarded: () {
                                  for (var item in s.items) {
                                    if (item.type == PlaylistItemType.version) {
                                      localVer.loadVersion(item.contentId!);
                                    }
                                  }
                                },
                              );
                            },
                          ),
                          // Save
                          if (widget.canEdit)
                            IconButton(
                              icon: Icon(
                                Icons.save,
                                color: colorScheme.onSurface,
                                size: 30,
                              ),
                              onPressed: () => _handleSave(),
                            ),
                        ]
                      : [],
                )
              : null,
          floatingActionButton: widget.canEdit
              ? FloatingActionButton(
                  onPressed: () => _openPlaylistEditSheet(),
                  backgroundColor: colorScheme.onSurface,
                  shape: const CircleBorder(),
                  child: Icon(Icons.add, color: colorScheme.onPrimary),
                )
              : null,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: s.items.isEmpty
                ? _buildEmptyState()
                : _buildItemsList(s.items),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.emptyPlaylist,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            AppLocalizations.of(context)!.emptyPlaylistInstructions,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<PlaylistItem> items) {
    return widget.canEdit
        ? ReorderableListView.builder(
            proxyDecorator: (child, index, animation) =>
                Material(type: MaterialType.transparency, child: child),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
            itemCount: items.length,
            itemBuilder: (_, index) => _buildPlaylistItem(items[index], index),
          )
        : ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) => _buildPlaylistItem(items[index], index),
          );
  }

  Widget _buildPlaylistItem(PlaylistItem item, int index) {
    switch (item.type) {
      case PlaylistItemType.version:
        return PlaylistVersionCard(
          key: ValueKey('idx_$index'),
          index: index,
          canEdit: widget.canEdit,
          versionId: item.contentId ?? -1,
          playlistId: widget.playlistID,
          itemId: item.id ?? -1,
          version: widget.playlistDto?.versions[item.firebaseContentId],
        );
      case PlaylistItemType.flowItem:
        return FlowItemCard(
          key: ValueKey('idx_$index'),
          index: index,
          flowItemID: item.contentId ?? -1,
          playlistID: widget.playlistID,
          canEdit: widget.canEdit,
          flowItem: widget.playlistDto != null
              ? FlowItem.fromFirestore(
                  widget.playlistDto!.flowItems[item.firebaseContentId]!,
                  playlistId: widget.playlistID,
                )
              : null,
        );
    }
  }

  Future<void> _handleSave() async {
    final nav = context.read<NavigationProvider>();

    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final localSch = context.read<LocalScheduleProvider>();
    final auth = context.read<MyAuthProvider>();
    final sel = context.read<SelectionProvider>();
    final flow = context.read<FlowItemProvider>();

    await localVer.persistCachedDeletions();
    await flow.persistDeletions();

    await play.savePlaylistItems(widget.playlistID);

    final schedule = await localSch.getScheduleWithPlaylistId(
      widget.playlistID,
    );

    if (schedule != null && schedule.scheduleState == ScheduleState.published) {
      await ScheduleSyncService().upsertScheduleToCloud(schedule, auth.id!);
    }

    sel.clearNewlyAddedVersionIds();

    play.clearUnsavedChanges();
    flow.clearUnsavedChanges();

    nav.pop();
  }

  void _openPlaylistEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return AddToPlaylistSheet(playlistID: widget.playlistID);
          },
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    try {
      context.read<PlaylistProvider>().cacheReposition(
        widget.playlistID,
        oldIndex,
        newIndex,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reordenar: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Tentar Novamente',
            textColor: Colors.white,
            onPressed: () => _onReorder(oldIndex, newIndex),
          ),
        ),
      );
    }
  }
}
