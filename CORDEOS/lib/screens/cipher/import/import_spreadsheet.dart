import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
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
        final path = result.files.first.path;

        if (mounted) {
          context.read<ImportProvider>().setSelectedFile(
            path!,
            fileName: result.files.first.name,
            fileSize: result.files.first.size,
          );
        }
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

  @override
  Widget build(BuildContext context) {
    final imp = context.read<ImportProvider>();

    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileSelectionSection(),
            const SizedBox(height: 16),
            if (imp.error != null) _buildErrorDisplay(),
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

    return Selector<
      ImportProvider,
      ({String? filePath, String? fileName, String? fileSize})
    >(
      selector: (context, imp) => (
        filePath: imp.filePath,
        fileName: imp.fileName,
        fileSize: imp.fileSize,
      ),
      builder: (context, s, child) {
        if (s.fileName == null) {
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
                        s.fileName!,
                        style: textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        s.fileSize ?? '',
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
      },
    );
  }

  Widget _buildSelectFileButton() {
    return FilledTextButton(
      onPressed: () => _pickPdfFile(),
      text: AppLocalizations.of(context)!.selectFile,
      isDark: true,
    );
  }

  Widget _buildErrorDisplay() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Selector<ImportProvider, String>(
                selector: (context, imp) => imp.error!,
                builder: (context, error, child) =>
                    Text(error, style: textTheme.bodySmall),
              ),
            ),
          ],
        ),
      ),
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

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (par.isParsing)
          CircularProgressIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainer,
          )
        else
          Selector<ImportProvider, bool>(
            selector: (context, imp) =>
                (imp.filePath == null || imp.isImporting),
            builder: (context, enabled, child) {
              return FilledTextButton(
                isDark: true,
                isDisabled: enabled,
                onPressed: _processAndNavigate(),
                text: AppLocalizations.of(context)!.processSpreadsheet,
              );
            },
          ),
      ],
    );
  }

  VoidCallback _processAndNavigate() {
    final imp = context.read<ImportProvider>();
    final par = context.read<ParserProvider>();
    final nav = context.read<NavigationProvider>();

    return () async {
      imp.setImportType(ImportType.spreadSheet);
      final imports = await imp.importText();
      if (imports.isEmpty) {
        throw Exception('Failed to import text from PDF');
      }

      final songs = <VersionDto>[];
      for (final import in imports) {
        final song = await par.parseCipher(import);
        if (song != null) songs.add(song);
      }

      nav.push(
        () => BatchImportStaging(songs: songs),
        keepAlive: true,
        showBottomNavBar: true,
        onPopCallback: () {
          imp.clearCache();
          par.clearCache();
        },
      );
    };
  }

  VoidCallback _clearSelectedFile() {
    final imp = context.read<ImportProvider>();

    return () {
      imp.clearSelectedFile();
      imp.clearSelectedFileName();
      imp.clearError();
    };
  }
}
