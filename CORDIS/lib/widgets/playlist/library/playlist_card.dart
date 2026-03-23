import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';

import 'package:cordis/screens/playlist/view_playlist.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/library/playlist_card_actions.dart';

class PlaylistCard extends StatelessWidget {
  final int playlistID;

  const PlaylistCard({super.key, required this.playlistID});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final sel = context.read<SelectionProvider>();
    final nav = context.read<NavigationProvider>();
    final play = context.read<PlaylistProvider>();

    return Selector<PlaylistProvider, Playlist?>(
      selector: (context, play) {
        return play.getPlaylist(playlistID);
      },
      builder: (context, playlist, child) {
        if (playlist == null) {
          return Center(child: CircularProgressIndicator());
        }

        final itemCount = playlist.items.length;
        // Card content
        return GestureDetector(
          onTap: () {
            final localVer = context.read<LocalVersionProvider>();
            final sect = context.read<SectionProvider>();

            sel.isSelectionMode
                ? null
                : nav.push(
                    () => ViewPlaylistScreen(playlistId: playlistID),
                    changeDetector: () => play.hasUnsavedChanges,
                    onChangeDiscarded: () async {
                      debugPrint('PLAYLIST VIEW - discarding Changes');
                      play.loadPlaylist(playlist.id);
                      for (var id in sel.newlyAddedVersionIds) {
                        debugPrint('\t - deleting version with id $id');
                        await localVer.deleteVersion(id);
                        await sect.deleteSectionsOfVersion(id);
                      }
                      play.clearUnsavedChanges();
                      sel.clearNewlyAddedVersionIds();
                    },
                    showBottomNavBar: true,
                  );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.surfaceContainerLowest),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // SELECTION CHECKBOX
                    sel.isSelectionMode
                        ? Checkbox(
                            value: sel.isSelected(playlistID),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                            onChanged: (isSelected) {
                              if (isSelected == null) return;

                              if (isSelected) {
                                sel.select(playlistID);
                              } else {
                                sel.deselect(playlistID);
                              }
                            },
                          )
                        : const SizedBox.shrink(),

                    // INFO
                    Expanded(
                      child: Column(
                        spacing: 2.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(playlist.name, style: textTheme.titleMedium),
                          Row(
                            spacing: 8,
                            children: [
                              Text(
                                itemCount != 1
                                    ? '$itemCount ${AppLocalizations.of(context)!.pluralPlaceholder(
                                        AppLocalizations.of(context)!.item, //
                                      )}'
                                    : '$itemCount ${AppLocalizations.of(context)!.item}',
                                style: textTheme.bodyMedium!.copyWith(
                                  color: colorScheme.shadow,
                                ),
                              ),
                              itemCount > 0
                                  ? Text(
                                      '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(playlist.getTotalDuration())}',
                                      style: textTheme.bodyMedium!.copyWith(
                                        color: colorScheme.shadow,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ACTIONS
                    sel.isSelectionMode
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: () => _openPlaylistActionsSheet(context),
                            icon: Icon(Icons.more_vert),
                          ),
                  ],
                ),
                if (!sel.isSelectionMode)
                  FilledTextButton(
                    text: AppLocalizations.of(
                      context,
                    )!.viewPlaceholder(AppLocalizations.of(context)!.playlist),
                    isDense: true,
                    onPressed: () {
                      final localVer = context.read<LocalVersionProvider>();
                      final sect = context.read<SectionProvider>();

                      nav.push(
                        () => ViewPlaylistScreen(playlistId: playlistID),
                        changeDetector: () => play.hasUnsavedChanges,
                        onChangeDiscarded: () async {
                          debugPrint('PLAYLIST VIEW - discarding Changes');
                          play.loadPlaylist(playlist.id);
                          for (var id in sel.newlyAddedVersionIds) {
                            debugPrint('\t - deleting version with id $id');
                            await localVer.deleteVersion(id);
                            await sect.deleteSectionsOfVersion(id);
                          }
                          play.clearUnsavedChanges();
                          sel.clearNewlyAddedVersionIds();
                        },
                        showBottomNavBar: true,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPlaylistActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PlaylistCardActionsSheet(playlistID: playlistID);
      },
    );
  }
}
