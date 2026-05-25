import 'dart:async';

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/edit_cipher.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/providers/cipher/import_provider.dart';
import 'package:provider/provider.dart';

class ImportTextScreen extends StatefulWidget {
  final int cipherID;
  final int versionID;

  const ImportTextScreen({super.key, this.cipherID = -1, this.versionID = -1});

  @override
  State<ImportTextScreen> createState() => _ImportTextScreenState();
}

class _ImportTextScreenState extends State<ImportTextScreen> {
  final TextEditingController _importTextController = TextEditingController();
  ParsingStrategy _strategy = ParsingStrategy.emptyLine;

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.importFromText,
          style: textTheme.titleMedium,
        ),
        leading: BackButton(onPressed: () => nav.attemptPop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextInputField(),
              _buildParsingStrategySection(),
              _buildImportButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputField() {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: TextField(
        expands: true,
        maxLines: null,
        selectAllOnFocus: true,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        textAlignVertical: TextAlignVertical(y: -1),
        controller: _importTextController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.pasteTextPrompt,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildParsingStrategySection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.parsingStrategy,
          style: textTheme.labelLarge,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.emptyLine,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.left,
              ),
            ),
            Switch(
              inactiveTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.surface,
              trackOutlineColor: WidgetStatePropertyAll<Color>(
                colorScheme.primary,
              ),
              thumbIcon: WidgetStatePropertyAll<Icon>(Icon(Icons.circle)),
              value: _strategy == ParsingStrategy.sectionLabels,
              onChanged: (value) => setState(() {
                _strategy = value
                    ? ParsingStrategy.sectionLabels
                    : ParsingStrategy.emptyLine;
              }),
            ),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.sectionLabels,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportButton() {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.import,
      isDark: true,
      isDisabled: _importTextController.text.isEmpty,
      onPressed: () async {
        await _parse();
      },
    );
  }

  Future<void> _parse() async {
    final sect = context.read<SectionProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();
    final nav = context.read<NavigationProvider>();
    final imp = context.read<ImportProvider>();
    final par = context.read<ParserProvider>();

    final text = _importTextController.text;
    if (text.isNotEmpty) {
      final parsingCipher = await imp.importFromText(_strategy, text);

      int versionID;
      int cipherID = widget.cipherID;
      final song = await par.parseCipher(parsingCipher);
      if (song != null) {
        if (widget.cipherID != -1) {
          final sections = song.sections.map(
            (key, value) => MapEntry(key, value.toDomain()),
          );
          for (final section in sections.values) {
            final newKey = sect.cacheAddSection(widget.versionID, section);
            localVer.addSectionToStruct(widget.versionID, newKey);
          }
          versionID = widget.versionID;
        } else {
          // CREATE NEW SONG
          cipherID = await ciph.upsertVersionDto(song);
          versionID = await localVer.upsertVersion(
            song.toDomain(cipherId: cipherID),
          );

          sect.setNewSectionsInCache(
            versionID,
            song.sections.map(
              (code, section) =>
                  MapEntry(code, Section.fromFirestore(section, versionID)),
            ),
          );

          await sect.saveSections(versionID);
        }

        // Navigate to edit cipher screen
        nav.pop();
        if (widget.cipherID == -1)
          nav.push(
            () => EditCipherScreen(
              versionID: versionID,
              cipherID: cipherID,
              versionType: VersionType.local,
            ),
            keepAlive: true,
            changeDetector: () {
              return ciph.hasUnsavedChanges || localVer.hasUnsavedChanges;
            },
            onChangeDiscarded: () async {
              await localVer.loadVersion(widget.versionID);
              await ciph.loadCipher(widget.cipherID);
            },
          );
      }
    }
  }
}
