import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/playlist/playlist.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/playlist/edit_playlist.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistCardActionsSheet extends StatelessWidget {
  final int playlistID;

  const PlaylistCardActionsSheet({super.key, required this.playlistID});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

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
                AppLocalizations.of(
                  context,
                )!.optionsPlaceholder(AppLocalizations.of(context)!.playlist),
                style: textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 32),
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
              final play = context.read<PlaylistProvider>();

              Navigator.of(context).pop(); // Close the bottom sheet
              nav.push(
                () => EditPlaylistScreen(playlistId: playlistID),
                changeDetector: () => play.hasUnsavedChanges,
                onChangeDiscarded: () => play.loadPlaylist(playlistID),
                showBottomNavBar: true,
              );
            },
          ),

          // duplicate
          FilledTextButton(
            text: AppLocalizations.of(context)!.duplicatePlaceholder(''),
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop();
              _duplicatePlaylist(context);
            },
          ),

          // delete
          FilledTextButton(
            text: AppLocalizations.of(context)!.delete,
            tooltip: AppLocalizations.of(context)!.deletePlaylistDescription,
            trailingIcon: Icons.chevron_right,
            isDangerous: true,
            isDiscrete: true,
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return DeleteConfirmationSheet(
                    itemType: AppLocalizations.of(context)!.playlist,
                    onConfirm: () async {
                      Navigator.of(context).pop();

                      await _deletePlaylist(context, nav);
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
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    NavigationProvider nav,
  ) async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();
    final flow = context.read<FlowItemProvider>();

    for (var item in play.getPlaylist(playlistID)!.items) {
      if (item.type == PlaylistItemType.version) {
        final cipherID = await localVer.deleteVersion(item.contentId!);

        if (cipherID != null) {
          ciph.clearCipherFromCache(cipherId: cipherID);
        }
      } else if (item.type == PlaylistItemType.flowItem) {
        await flow.deleteFlowItem(item.contentId!);
      }
    }
    await play.deletePlaylist(playlistID);
    nav.pop();
  }

  Future<void> _duplicatePlaylist(BuildContext context) async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final flow = context.read<FlowItemProvider>();

    final userID = context.read<UserProvider>().getLocalIdByFirebaseId(
      context.read<MyAuthProvider>().id!,
    )!;

    // Create pruned Playlist copy
    final playlist = play.getPlaylist(playlistID);

    await play.createPlaylistFromDomain(
      Playlist(
        id: -1,
        name: '${playlist!.name} (${AppLocalizations.of(context)!.copy})',
        createdBy: userID,
      ),
    );

    // Create new Items and assign them to the newPlaylist
    for (var item in playlist.items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = (await localVer.fetchVersion(item.contentId!))!;

          if (!context.mounted) {
            throw Exception('Context is not mounted');
          }

          localVer.setNewVersionInCache(
            version.copyWith(
              id: -1,
              firebaseID: '',
              versionName:
                  '${version.versionName} (${AppLocalizations.of(context)!.copy})',
            ),
          );
          final newId = await localVer.createVersion();

          play.cacheAddVersion(playlistID, newId);

        case PlaylistItemType.flowItem:
          final flowItem = (await flow.fetchFlowItem(item.contentId!))!;

          if (!context.mounted) {
            throw Exception('Context is not mounted');
          }

          await flow.create(
            flowItem.copyWith(
              firebaseId: '',
              title:
                  "${flowItem.title} (${AppLocalizations.of(context)!.copy})",
            ),
          );
          break;
      }
    }
  }
}
