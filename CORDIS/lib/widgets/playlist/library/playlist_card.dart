import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/playlist/view_playlist.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/library/playlist_card_actions.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';

class PlaylistCard extends StatelessWidget {
  final int playlistId;

  const PlaylistCard({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer5<
      PlaylistProvider,
      NavigationProvider,
      SelectionProvider,
      LocalScheduleProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            playlistProvider,
            navigationProvider,
            selectionProvider,
            localScheduleProvider,
            authProvider,
            child,
          ) {
            final playlist = playlistProvider.getPlaylistById(playlistId)!;

            final itemCount = playlist.items.length;

            // Card content
            return GestureDetector(
              onTap: () {
                selectionProvider.isSelectionMode
                    ? null
                    : navigationProvider.push(
                        ViewPlaylistScreen(playlistId: playlistId),
                        changeDetector: () => context.read<PlaylistProvider>().hasUnsavedChanges,
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
                        selectionProvider.isSelectionMode
                            ? Checkbox(
                                value: selectionProvider.isSelected(playlistId),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                onChanged: (isSelected) {
                                  if (isSelected == null) return;

                                  if (isSelected) {
                                    selectionProvider.select(playlistId);
                                  } else {
                                    selectionProvider.deselect(playlistId);
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
                        selectionProvider.isSelectionMode
                            ? const SizedBox.shrink()
                            : IconButton(
                                onPressed: () =>
                                    _openPlaylistActionsSheet(context),
                                icon: Icon(Icons.more_vert),
                              ),
                      ],
                    ),
                    if (!selectionProvider.isSelectionMode)
                      FilledTextButton(
                        text: AppLocalizations.of(context)!.viewPlaceholder(
                          AppLocalizations.of(context)!.playlist,
                        ),
                        isDense: true,
                        onPressed: () {
                          navigationProvider.push(
                            ViewPlaylistScreen(playlistId: playlistId),
                            changeDetector: () => context.read<PlaylistProvider>().hasUnsavedChanges,
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
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return PlaylistCardActionsSheet(playlistId: playlistId);
          },
        );
      },
    );
  }
}
