import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/import/batch_staging.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/parsing_cipher.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/import_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class ImportSpreadSheetScreen extends StatefulWidget {
  const ImportSpreadSheetScreen({super.key});

  @override
  State<ImportSpreadSheetScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends State<ImportSpreadSheetScreen> {
  ImportFile? _file;

  /// Opens file picker and allows user to select a PDF file
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );

      // User selected a file
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _file = ImportFile(
            importType: ImportType.spreadSheet,
            parsingStrategy: ParsingStrategy.emptyLine,
            importVariation: ImportVariation.textDirect,
            path: file.path,
            name: file.name,
            size: file.size,
          );
        });
      }
      // If result is null, user canceled - do nothing
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(
                AppLocalizations.of(context)!.selectFile,
                e.toString(),
              ),
            ),
          ),
        );
      }
    }
  }

  String _parseFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    }
    if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileSelectionSection(),
            const Spacer(),
            _buildImportInstructions(),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final nav = context.read<NavigationProvider>();
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.importFromSpreadsheet,
        style: textTheme.titleMedium,
      ),
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
    );
  }

  Widget _buildFileSelectionSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_file == null) {
      return _buildSelectFileButton();
    } else {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          spacing: 8,
          children: [
            Icon(Icons.grid_on_sharp, size: 24, color: colorScheme.shadow),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _file!.name,
                    style: textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _parseFileSize(_file!.size),
                    style: textTheme.bodySmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _clearSelectedFile(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.shadow,
                ),
                width: 20,
                height: 20,
                child: Icon(
                  Icons.close_rounded,
                  color: colorScheme.surfaceContainerHighest,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSelectFileButton() {
    return FilledTextButton(
      onPressed: () => _pickPdfFile(),
      text: AppLocalizations.of(context)!.selectFile,
      isDark: true,
    );
  }

  Widget _buildImportInstructions() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        color: colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(Icons.info, color: colorScheme.shadow),
              Text(l10n.howToImport, style: textTheme.titleMedium),
            ],
          ),
          Text(l10n.spreadsheetImportInstructions, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final colorScheme = Theme.of(context).colorScheme;

    final par = context.read<ParserProvider>();

    return par.isParsing
        ? CircularProgressIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainer,
          )
        : FilledTextButton(
            isDark: true,
            isDisabled: _file == null,
            onPressed: _processAndNavigate(),
            text: AppLocalizations.of(context)!.processSpreadsheet,
          );
  }

  VoidCallback _processAndNavigate() {
    if (_file == null) return () {};

    final imp = context.read<ImportProvider>();
    final par = context.read<ParserProvider>();
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final nav = context.read<NavigationProvider>();

    return () async {
      final imports = await imp.importFromSpreadsheet(_file!);
      if (imports.isEmpty) {
        throw Exception('Failed to import text from PDF');
      }

      final versionIDs = <int>[];
      for (final import in imports) {
        final song = await par.parseCipher(import);
        if (song != null) {
          // CREATE NEW SONG
          final cipherID = await ciph.upsertVersionDto(song);
          final versionID = await localVer.upsertVersion(
            song.toDomain(cipherId: cipherID),
          );
          versionIDs.add(versionID);

          sect.setNewSectionsInCache(
            versionID,
            song.sections.map(
              (code, section) =>
                  MapEntry(code, Section.fromFirestore(section, versionID)),
            ),
          );

          await sect.saveSections(versionID);
        }
      }

      nav.push(
        () => BatchImportStaging(versionIDs: versionIDs),
        keepAlive: true,
        showBottomNavBar: true,
        onPopCallback: () {
          par.clearCache();
        },
      );
    };
  }

  VoidCallback _clearSelectedFile() {
    return () {
      setState(() {
        _file == null;
      });
    };
  }
}
