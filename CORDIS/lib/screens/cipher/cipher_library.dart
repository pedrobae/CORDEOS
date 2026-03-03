import 'package:cordis/l10n/app_localizations.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/selection_provider.dart';

import 'package:cordis/widgets/ciphers/library/scroll_view.dart';

class CipherLibraryScreen extends StatefulWidget {
  final int? playlistId;

  const CipherLibraryScreen({super.key, this.playlistId});

  @override
  State<CipherLibraryScreen> createState() => _CipherLibraryScreenState();
}

class _CipherLibraryScreenState extends State<CipherLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectionProvider = Provider.of<SelectionProvider>(context, listen: false);


    return Consumer2<CipherProvider, CloudVersionProvider>(
      builder:
          (
            context,
            cipherProvider,
            cloudVersionProvider,
            child,
          ) {
            return Scaffold(
              appBar: selectionProvider.isSelectionMode
                  ? AppBar(
                      leading: const BackButton(),
                      title: Text(
                        AppLocalizations.of(context)!.addToPlaylist,
                        style: theme.textTheme.titleMedium,
                      ),
                    )
                  : null,
              body: Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchCiphers,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide(
                            color: colorScheme.surfaceContainer,
                          ),
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
                    ),
                    Expanded(
                      child: CipherScrollView(playlistId: widget.playlistId),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
