import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistCardActionsSheet extends StatelessWidget {
  final int playlistId;

  const PlaylistCardActionsSheet({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      NavigationProvider,
      PlaylistProvider,
      LocalVersionProvider,
      FlowItemProvider
    >(
      builder:
          (
            context,
            navigationProvider,
            playlistProvider,
            versionProvider,
            flowItemProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;

            // Your widget build logic here
            return Container(
              padding: const EdgeInsets.all(16.0),
              color: colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.optionsPlaceholder(
                          AppLocalizations.of(context)!.playlist,
                        ),
                        style: textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface,
                          size: 32,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  /// ACTIONS
                  // rename
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.renamePlaceholder(''),
                    trailingIcon: Icons.chevron_right,
                    isDiscrete: true,
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      navigationProvider.push(
                        interceptPop: true,
                        EditPlaylistScreen(playlistId: playlistId),
                        showBottomNavBar: true,
                      );
                    },
                  ),

                  // duplicate
                  FilledTextButton(
                    text: AppLocalizations.of(
                      context,
                    )!.duplicatePlaceholder(''),
                    trailingIcon: Icons.chevron_right,
                    isDiscrete: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _duplicatePlaylist(
                        context,
                        playlistProvider,
                        versionProvider,
                        flowItemProvider,
                      );
                    },
                  ),

                  // delete
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.delete,
                    tooltip: AppLocalizations.of(
                      context,
                    )!.deletePlaylistDescription,
                    trailingIcon: Icons.chevron_right,
                    isDangerous: true,
                    isDiscrete: true,
                    onPressed: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return BottomSheet(
                            shape: LinearBorder(),
                            onClosing: () {},
                            builder: (context) {
                              return DeleteConfirmationSheet(
                                itemType: AppLocalizations.of(
                                  context,
                                )!.playlist,
                                onConfirm: () async {
                                  Navigator.of(context).pop();

                                  await _deletePlaylist(
                                    playlistProvider,
                                    versionProvider,
                                    navigationProvider,
                                    flowItemProvider,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  SizedBox(height: 16),
                ],
              ),
            );
          },
    );
  }

  Future<void> _deletePlaylist(
    PlaylistProvider playlistProvider,
    LocalVersionProvider versionProvider,
    NavigationProvider navigationProvider,
    FlowItemProvider flowItemProvider,
  ) async {
    for (var item in playlistProvider.getPlaylistById(playlistId)!.items) {
      if (item.type == PlaylistItemType.version) {
        await versionProvider.deleteVersion(item.contentId!);
      } else if (item.type == PlaylistItemType.flowItem) {
        await flowItemProvider.deleteFlowItem(item.contentId!);
      }
    }
    await playlistProvider.deletePlaylist(playlistId);
    navigationProvider.pop();
  }

  Future<void> _duplicatePlaylist(
    BuildContext context,
    PlaylistProvider playlistProvider,
    LocalVersionProvider localVersionProvider,
    FlowItemProvider flowItemProvider,
  ) async {
    final userID = context.read<UserProvider>().getLocalIdByFirebaseId(
      context.read<MyAuthProvider>().id!,
    )!;

    // Create pruned Playlist copy
    final playlist = playlistProvider.getPlaylistById(playlistId);

    await playlistProvider.createPlaylistFromDomain(
      Playlist(
        id: -1,
        name: '${playlist!.name} ${AppLocalizations.of(context)!.copySuffix}',
        createdBy: userID,
      ),
    );

    // Create new Items and assign them to the newPlaylist
    for (var item in playlist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = (await localVersionProvider.fetchVersion(
            item.contentId!,
          ))!;

          if (!context.mounted) {
            throw Exception('Context is not mounted');
          }

          localVersionProvider.setNewVersionInCache(
            version.copyWith(
              id: -1,
              firebaseId: '',
              versionName:
                  '${version.versionName} ${AppLocalizations.of(context)!.copySuffix}',
            ),
          );
          final newId = (await localVersionProvider.createVersion())!;

          playlistProvider.cacheAddVersion(playlistId, newId);

        case PlaylistItemType.flowItem:
          final flowItem = (await flowItemProvider.fetchFlowItem(
            item.contentId!,
          ))!;

          if (!context.mounted) {
            throw Exception('Context is not mounted');
          }

          await flowItemProvider.createFlowItem(
            flowItem.copyWith(
              firebaseId: '',
              title:
                  "${flowItem.title} ${AppLocalizations.of(context)!.copySuffix}",
            ),
          );
          break;
      }
    }
  }
}
