import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/widgets/playlist/library/playlist_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';

class PlaylistLibraryScreen extends StatefulWidget {
  const PlaylistLibraryScreen({super.key});

  @override
  State<PlaylistLibraryScreen> createState() => _PlaylistLibraryScreenState();
}

class _PlaylistLibraryScreenState extends State<PlaylistLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlaylistProvider>().loadPlaylists();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sel = Provider.of<SelectionProvider>(context, listen: false);

    return Consumer<PlaylistProvider>(
      builder: (context, play, child) {
        return Padding(
          padding: sel.isSelectionMode
              ? EdgeInsets.zero
              : const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8.0,
            children: [
              _buildSearchBar(play),
              const Expanded(child: PlaylistScrollView()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(PlaylistProvider play) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchPlaylist,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        suffixIcon: const Icon(Icons.search),
        fillColor: colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      ),
      onChanged: (value) => play.setSearchTerm(value),
    );
  }
}
