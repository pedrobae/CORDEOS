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

    return Consumer<PlaylistProvider>(
      builder:
          (context, playlistProvider, child) {
            // Handle loading state
            if (playlistProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle error state
            if (playlistProvider.error != null) {
              return Center(
                child: Column(
                  children: [
                    Text(playlistProvider.error!),
                    ElevatedButton(
                      onPressed: () {
                        playlistProvider.loadPlaylists();
                      },
                      child: Text(AppLocalizations.of(context)!.tryAgain),
                    ),
                  ],
                ),
              );
            }

            final List<int> playlistIds = playlistProvider.filteredPlaylists;

            // Display playlist list
            return RefreshIndicator(
              onRefresh: () async {
                playlistProvider.loadPlaylists();
              },
              child: playlistProvider.filteredPlaylists.isEmpty
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
                      itemCount: playlistProvider.filteredPlaylists.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: PlaylistCard(playlistId: playlistIds[index]),
                        );
                      },
                    ),
            );
          },
    );
  }
}
