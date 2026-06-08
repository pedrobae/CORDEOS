import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';

import 'package:cordeos/widgets/ciphers/library/scroll_view.dart';

class CipherLibraryScreen extends StatefulWidget {
  const CipherLibraryScreen({super.key});

  @override
  State<CipherLibraryScreen> createState() => _CipherLibraryScreenState();
}

class _CipherLibraryScreenState extends State<CipherLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final sel = context.read<SelectionProvider>();
    return Scaffold(
      appBar: sel.isSelectionMode
          ? AppBar(
              leading: const BackButton(),
              title: Text(l10n.addToPlaylist, style: textTheme.titleMedium),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.only(top: 8, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            _buildSearchBar(),
            Expanded(child: CipherScrollView()),
            if (sel.isSelectionMode) _buildAddToPlaylistButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final cipherProvider = Provider.of<CipherProvider>(context, listen: false);
    final cloudVersionProvider = Provider.of<CloudVersionProvider>(
      context,
      listen: false,
    );
    // Search Bar
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchCiphers,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        suffixIcon: const Icon(Icons.search),
        fillColor: colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      ),
      onChanged: (value) {
        cipherProvider.setSearchTerm(value);
        cloudVersionProvider.setSearchTerm(value);
      },
    );
  }

  Widget _buildAddToPlaylistButton() {
    final l10n = AppLocalizations.of(context)!;

    return Selector<SelectionProvider, bool>(
      selector: (context, sel) => sel.selectedItemIds.length < 1,
      builder: (context, emptySelection, child) {
        return FilledTextButton(
          text: l10n.addToPlaylist,
          isDiscrete: true,
          isDisabled: emptySelection,
          isDark: true,
          onPressed: _duplicateAndAddToPlaylist(),
        );
      },
    );
  }

  VoidCallback _duplicateAndAddToPlaylist() {
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final sel = context.read<SelectionProvider>();
    final play = context.read<PlaylistProvider>();
    final nav = context.read<NavigationProvider>();

    final l10n = AppLocalizations.of(context)!;

    return () async {
      final selectedItems = sel.selectedItemIds;

      final playlistName = play.getPlaylist(sel.targetId!)?.name;

      for (final versionID in selectedItems) {
        final newName = l10n.playlistVersionName(playlistName ?? '');
        final version = localVer.getVersion(versionID);

        if (version == null) continue;

        final newVersion = version.copyWith(
          versionName: newName,
          firebaseID: '',
        );

        localVer.setNewVersionInCache(newVersion);

        final newVersionID = await localVer.createVersion(
          cipherID: version.cipherID,
        );

        await sect.ensureAreLoaded(version.id!, version.songStructure);
        sect.cacheCopyOfVersion(version.id!, newVersionID);
        await sect.saveSections(newVersionID);

        sel.addVersionIdToDelete(newVersionID);

        play.cacheAddVersion(sel.targetId!, newVersionID);
      }
      sel.clearSelection();
      nav.pop();
    };
  }
}
