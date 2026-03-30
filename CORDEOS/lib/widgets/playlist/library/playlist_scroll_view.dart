import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/widgets/playlist/library/playlist_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistScrollView extends StatefulWidget {
  const PlaylistScrollView({super.key});

  @override
  State<PlaylistScrollView> createState() => _PlaylistScrollViewState();
}

class _PlaylistScrollViewState extends State<PlaylistScrollView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final play = context.read<PlaylistProvider>();

    // Display playlist list
    return Selector<PlaylistProvider, List<int>>(
      selector: (_, provider) => provider.filteredPlaylists,
      builder: (context, playlistIds, child) {
        return RefreshIndicator(
          onRefresh: () async {
            play.loadPlaylists();
          },
          child: playlistIds.isEmpty
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
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 500,
                  itemCount: playlistIds.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: PlaylistCard(playlistID: playlistIds[index]),
                    );
                  },
                ),
        );
      },
    );
  }
}
