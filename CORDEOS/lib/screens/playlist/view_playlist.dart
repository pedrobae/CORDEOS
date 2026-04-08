import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/playlist/playlist.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/play/play_state_provider.dart';
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
  final int playlistId; // Receive the playlist ID from the parent

  const ViewPlaylistScreen({super.key, required this.playlistId});

  @override
  State<ViewPlaylistScreen> createState() => _ViewPlaylistScreenState();
}

class _ViewPlaylistScreenState extends State<ViewPlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector<PlaylistProvider, Playlist?>(
      selector: (context, play) => play.getPlaylist(widget.playlistId),
      builder: (context, playlist, child) {
        if (playlist == null) {
          return Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              color: colorScheme.onSurface,
              onPressed: () => nav.attemptPop(context),
            ),
            title: Text(playlist.name, style: textTheme.titleMedium),
            actions: [
              // Play
              IconButton(
                icon: Icon(Icons.play_circle_fill_rounded, color: colorScheme.onSurface, size: 30,),
                onPressed: () {
                  final localVer = context.read<LocalVersionProvider>();
                  final sect = context.read<SectionProvider>();
                  final state = context.read<PlayStateProvider>();
                  final scroll = context.read<ScrollProvider>();

                  scroll.disableAutoScrollMode();
                  state.setItemCount(playlist.items.length);
                  for (var item in playlist.items) {
                    state.appendItem(item);
                  }

                  nav.push(
                    () => PlayPlaylist(canEdit: true),
                    changeDetector: () {
                      return localVer.hasUnsavedChanges ||
                          sect.hasUnsavedChanges;
                    },
                    onChangeDiscarded: () {
                      for (var item in playlist.items) {
                        if (item.type == PlaylistItemType.version) {
                          localVer.loadVersion(item.contentId!);
                        }
                      }
                    },
                  );
                },
              ),
              // Save
              IconButton(
                icon: Icon(Icons.save, color: colorScheme.onSurface, size: 30,),
                onPressed: () => _handleSave(playlist, nav),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openPlaylistEditSheet(),
            backgroundColor: colorScheme.onSurface,
            shape: const CircleBorder(),
            child: Icon(Icons.add, color: colorScheme.onPrimary),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: playlist.items.isEmpty
                ? _buildEmptyState()
                : _buildItemsList(playlist),
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

  Widget _buildItemsList(Playlist playlist) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      proxyDecorator: (child, index, animation) =>
          Material(type: MaterialType.transparency, child: child),
      buildDefaultDragHandles: false,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      onReorder: (oldIndex, newIndex) =>
          _onReorder(playlist, oldIndex, newIndex),
      itemCount: playlist.items.length,
      itemBuilder: (BuildContext context, int index) {
        final item = playlist.items[index];
        return _buildPlaylistItem(item, index);
      },
    );
  }

  Widget _buildPlaylistItem(PlaylistItem item, int index) {
    switch (item.type) {
      case PlaylistItemType.version:
        return PlaylistVersionCard(
          key: ValueKey('ver_${item.id}_idx_$index'),
          index: index,
          versionId: item.contentId!,
          playlistId: widget.playlistId,
          itemId: item.id ?? -1,
        );
      case PlaylistItemType.flowItem:
        return FlowItemCard(
          key: ValueKey('flow_${item.id}_idx_$index'),
          index: index,
          flowItemID: item.contentId ?? item.id!,
          playlistID: widget.playlistId,
        );
    }
  }

  Future<void> _handleSave(Playlist playlist, NavigationProvider nav) async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final localSch = context.read<LocalScheduleProvider>();
    final auth = context.read<MyAuthProvider>();
    final sel = context.read<SelectionProvider>();

    localVer.persistCachedDeletions();

    play.saveFromCache(playlist.id);

    final schedule = await localSch.getScheduleWithPlaylistId(
      widget.playlistId,
    );

    if (schedule != null && schedule.scheduleState == ScheduleState.published) {
      ScheduleSyncService().upsertScheduleToCloud(schedule, auth.id!);
    }

    sel.clearNewlyAddedVersionIds();

    play.clearUnsavedChanges();

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
            return AddToPlaylistSheet(playlistID: widget.playlistId);
          },
        );
      },
    );
  }

  void _onReorder(Playlist playlist, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    try {
      context.read<PlaylistProvider>().cacheReposition(
        playlist.id,
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
            onPressed: () => _onReorder(playlist, oldIndex, newIndex),
          ),
        ),
      );
    }
  }
}
