import 'package:azlistview/azlistview.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/widgets/playlist/library/playlist_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Model for AzListView that holds playlist data
class PlaylistListItem extends ISuspensionBean {
  final int id;
  final String name;
  String tag = '';

  PlaylistListItem({required this.id, required this.name}) {
    // Extract first letter for alphabet grouping, handle special chars
    if (name.isEmpty) {
      tag = '#';
    } else {
      final firstChar = name[0].toUpperCase();
      tag = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';
    }
  }

  @override
  String getSuspensionTag() => tag;
}

class PlaylistScrollView extends StatefulWidget {
  const PlaylistScrollView({super.key});

  @override
  State<PlaylistScrollView> createState() => _PlaylistScrollViewState();
}

class _PlaylistScrollViewState extends State<PlaylistScrollView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final play = context.read<PlaylistProvider>();

    // Display playlist list
    return Selector<PlaylistProvider, List<PlaylistListItem>>(
      selector: (_, provider) {
        final filteredIds = provider.filteredPlaylists;
        final items = filteredIds.map((id) {
          final playlist = provider.getPlaylist(id);
          return PlaylistListItem(id: id, name: playlist?.name ?? '');
        }).toList();

        // Sort and set suspension status for AzListView
        SuspensionUtil.sortListBySuspensionTag(items);
        SuspensionUtil.setShowSuspensionStatus(items);

        return items;
      },
      builder: (context, items, child) {
        return RefreshIndicator(
          onRefresh: () async {
            play.loadPlaylists();
          },
          child: items.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 64),
                    Text(
                      AppLocalizations.of(context)!.emptyPlaylistLibrary,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : AzListView(
                  data: items,
                  physics: const AlwaysScrollableScrollPhysics(),
                  indexBarData: SuspensionUtil.getTagIndexList(items),
                  indexBarOptions: IndexBarOptions(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                        left: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                        top: BorderSide(
                          color: colorScheme.surfaceContainerLowest,
                        ),
                      ),
                    ),
                    needRebuild: false,
                    indexHintAlignment: Alignment.centerRight,
                    indexHintOffset: const Offset(-20, 0),
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  itemCount: items.length,
                  padding: const EdgeInsets.only(right: 38),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: PlaylistCard(playlistID: item.id),
                    );
                  },
                ),
        );
      },
    );
  }
}
