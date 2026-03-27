import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/widgets/playlist/library/playlist_card.dart';
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

    final List<int> playlistIds = play.filteredPlaylists;

    // Display playlist list
    return RefreshIndicator(
      onRefresh: () async {
        play.loadPlaylists();
      },
      child: play.filteredPlaylists.isEmpty
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
              itemCount: play.filteredPlaylists.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: PlaylistCard(playlistID: playlistIds[index]),
                );
              },
            ),
    );
  }
}
