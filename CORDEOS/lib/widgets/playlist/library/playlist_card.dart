import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/models/domain/playlist/playlist.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';

import 'package:cordeos/screens/playlist/view_playlist.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/playlist/library/playlist_card_actions.dart';

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

    return Selector2<PlaylistProvider, SelectionProvider, (Playlist?, bool)>(
      selector: (context, play, sel) {
        return (
          play.getPlaylist(playlistID),
          sel.isSelected(playlistID),
        );
      },
      builder: (context, data, child) {
        final playlist = data.$1;
        final isSelected = data.$2;

        if (playlist == null) {
          return Center(child: CircularProgressIndicator());
        }

        final itemCount = playlist.items.length;
        // Card content
        return GestureDetector(
          onTap: () {
            final localVer = context.read<LocalVersionProvider>();
            final sect = context.read<SectionProvider>();
            final flow = context.read<FlowItemProvider>();

            sel.isSelectionMode
                ? sel.toggleSelection(playlistID, exclusive: true)
                : nav.push(
                    () => ViewPlaylistScreen(playlistId: playlistID),
                    changeDetector: () {
                      return play.hasUnsavedChanges ||
                          flow.hasUnsavedChanges ||
                          localVer.hasUnsavedChanges ||
                          sect.hasUnsavedChanges;
                    },
                    onChangeDiscarded: () async {
                      debugPrint('PLAYLIST VIEW - discarding Changes');
                      play.loadPlaylist(playlist.id);
                      for (var id in sel.newlyAddedVersionIds) {
                        debugPrint('\t - deleting version with id $id');
                        await localVer.deleteVersion(id);
                        await sect.deleteSectionsOfVersion(id);
                      }
                      play.clearUnsavedChanges();
                      flow.clearUnsavedChanges();
                      localVer.clearUnsavedChanges();
                      sect.clearUnsavedChanges();
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
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // SELECTION CHECKBOX
                  sel.isSelectionMode
                      ? isSelected
                            ? Icon(Icons.check_box, color: colorScheme.primary)
                            : Icon(
                                Icons.check_box_outline_blank,
                                color: colorScheme.shadow,
                              )
                      : const SizedBox.shrink(),
              
                  // INFO
                  Expanded(
                    child: Column(
                      spacing: 2.0,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              style: textTheme.bodyMedium,
                            ),
                            itemCount > 0
                                ? Text(
                                    playlist.getTotalDuration() != Duration.zero
                                        ? '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(playlist.getTotalDuration())}'
                                        : '',
                                    style: textTheme.bodyMedium,
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
                      : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openPlaylistActionsSheet(context),
                        child: SizedBox(
                          height: double.infinity,
                          width: 40,
                          child: Icon(
                              Icons.more_vert,
                            ),
                        ),
                      ),
                ],
              ),
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
