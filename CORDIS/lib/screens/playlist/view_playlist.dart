import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';

import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/services/sync_service.dart';

import 'package:cordis/widgets/playlist/viewer/add_to_playlist_sheet.dart';

import 'package:cordis/widgets/playlist/viewer/version_card.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_card.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playlistProvider = context.read<PlaylistProvider>();
      final versionProvider = context.read<LocalVersionProvider>();
      final flowItemProvider = context.read<FlowItemProvider>();

      await playlistProvider.loadPlaylist(widget.playlistId);

      // Load versions for the playlist items
      final items =
          playlistProvider.getPlaylistById(widget.playlistId)?.items ?? [];

      for (var item in items) {
        if (item.type == PlaylistItemType.version) {
          await versionProvider.loadVersion(item.contentId!);
        } else if (item.type == PlaylistItemType.flowItem) {
          await flowItemProvider.loadFlowItem(item.contentId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer4<
      PlaylistProvider,
      NavigationProvider,
      LocalScheduleProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            playlistProvider,
            navigationProvider,
            localScheduleProvider,
            authProvider,
            child,
          ) {
            final playlist = playlistProvider.getPlaylistById(
              widget.playlistId,
            );
            // Handle loading state
            if (playlist == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  color: colorScheme.onSurface,
                  onPressed: () {
                    navigationProvider.attemptPop(context);
                  },
                ),
                title: Text(playlist.name, style: theme.textTheme.titleMedium),
                actions: [
                  IconButton(
                    icon: Icon(Icons.save, color: colorScheme.onSurface),
                    onPressed: () async {
                      playlistProvider.updatePlaylistFromCache(
                        widget.playlistId,
                      );
                      // CHECK IF THE PLAYLIST IS ASSOSSIATED WITH A PUBLISHED SCHEDULE
                      final schedule = await localScheduleProvider
                          .getScheduleWithPlaylistId(widget.playlistId);
                      if (schedule != null &&
                          schedule.scheduleState == ScheduleState.published) {
                        // If so, update the cloud version
                        ScheduleSyncService().scheduleToCloud(
                          schedule,
                          authProvider.id!,
                        );
                      }
                      navigationProvider.pop();
                    },
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  _openPlaylistEditSheet(context);
                },
                backgroundColor: colorScheme.onSurface,
                shape: const CircleBorder(),
                child: Icon(Icons.add, color: colorScheme.onPrimary),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: playlist.items.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.emptyPlaylist,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.emptyPlaylistInstructions,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    // ITEMS LIST
                    : Builder(
                        builder: (context) {
                          return ReorderableListView.builder(
                            shrinkWrap: true,
                            proxyDecorator: (child, index, animation) =>
                                Material(
                                  type: MaterialType.transparency,
                                  child: child,
                                ),
                            buildDefaultDragHandles: false,
                            physics: const ClampingScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            onReorder: (oldIndex, newIndex) => _onReorder(
                              context,
                              playlist,
                              oldIndex,
                              newIndex,
                            ),
                            itemCount: playlist.items.length,
                            itemBuilder: (BuildContext context, int index) {
                              final playlistItem = playlist.items[index];

                              switch (playlistItem.type) {
                                case PlaylistItemType.version:
                                  return PlaylistVersionCard(
                                    key: ValueKey(
                                      'playlist_version_${playlistItem.id}',
                                    ),
                                    index: index,
                                    versionId: playlistItem.contentId,
                                    playlistId: widget.playlistId,
                                    itemId: playlistItem.id!,
                                  );
                                case PlaylistItemType.flowItem:
                                  return FlowItemCard(
                                    key: ValueKey(
                                      'flow_item_${playlistItem.id}',
                                    ),
                                    index: index,
                                    flowItemId:
                                        playlistItem.contentId ??
                                        playlistItem.id!,
                                    playlistId: widget.playlistId,
                                  );
                              }
                            },
                          );
                        },
                      ),
              ),
            );
          },
    );
  }

  void _openPlaylistEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (BuildContext context) {
            return AddToPlaylistSheet(playlistId: widget.playlistId);
          },
        );
      },
    );
  }

  void _onReorder(
    BuildContext context,
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reordenar: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () =>
                  _onReorder(context, playlist, oldIndex, newIndex),
            ),
          ),
        );
      }
    }
  }
}
