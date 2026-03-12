import 'package:cordis/l10n/app_localizations.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/selection_provider.dart';

import 'package:cordis/widgets/ciphers/library/scroll_view.dart';

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

    final sel = Provider.of<SelectionProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: sel.isSelectionMode
          ? AppBar(
              leading: const BackButton(),
              title: Text(
                AppLocalizations.of(context)!.addToPlaylist,
                style: textTheme.titleMedium,
              ),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            _buildSearchBar(context),
            Expanded(child: CipherScrollView()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
}
