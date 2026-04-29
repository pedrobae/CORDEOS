import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/edit_cipher.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/import_provider.dart';
import 'package:flutter/material.dart';

class ImportPdfScreen extends StatefulWidget {
  final int cipherID;
  final int versionID;
  const ImportPdfScreen({super.key, this.versionID = -1, this.cipherID = -1});

  @override
  State<ImportPdfScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends State<ImportPdfScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final imp = context.read<ImportProvider>();
        imp.setImportType(ImportType.pdf);
        imp.setImportVariation(ImportVariation.pdfNoColumns);
      }
    });
  }

  /// Opens file picker and allows user to select a PDF file
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
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
                AppLocalizations.of(context)!.selectPDFFile,
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
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final localVer = Provider.of<LocalVersionProvider>(context, listen: false);
    final ciph = Provider.of<CipherProvider>(context, listen: false);

    return Consumer2<ImportProvider, ParserProvider>(
      builder: (context, imp, par, child) {
        return Scaffold(
          appBar: _buildAppBar(nav),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFileSelectionSection(imp),
                const SizedBox(height: 16),
                _buildColumnsToggle(imp),
                if (imp.error != null) _buildErrorDisplay(imp),
                const Spacer(),
                _buildImportInstructions(),
                _buildActionButtons(imp, par, nav, localVer, ciph),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.importFromPDF,
        style: textTheme.titleMedium,
      ),
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
    );
  }

  Widget _buildFileSelectionSection(ImportProvider imp) {
    return imp.selectedFile != null
        ? _buildSelectedFileDisplay(imp)
        : _buildSelectFileButton(imp);
  }

  Widget _buildSelectedFileDisplay(ImportProvider imp) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 24,
            color: colorScheme.shadow,
          ),
          Expanded(
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imp.selectedFileName!,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  imp.fileSize ?? '',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _clearSelectedFile(imp),
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

  Widget _buildSelectFileButton(ImportProvider imp) {
    return FilledTextButton(
      onPressed: () => imp.isImporting ? null : _pickPdfFile(),
      text: AppLocalizations.of(context)!.selectPDFFile,
      isDark: true,
    );
  }

  Widget _buildColumnsToggle(ImportProvider imp) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.hasColumns,
          style: textTheme.titleMedium,
        ),
        Switch(
          value: imp.importVariation == ImportVariation.pdfWithColumns,
          onChanged: (value) {
            imp.setImportVariation(
              value
                  ? ImportVariation.pdfWithColumns
                  : ImportVariation.pdfNoColumns,
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(ImportProvider imp) {
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
            Expanded(child: Text(imp.error!, style: textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }

  Widget _buildImportInstructions() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              Text(
                AppLocalizations.of(context)!.howToImport,
                style: textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            AppLocalizations.of(context)!.importInstructions,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    ImportProvider imp,
    ParserProvider par,
    NavigationProvider nav,
    LocalVersionProvider localVer,
    CipherProvider ciph,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
          FilledTextButton(
            isDark: true,
            isDisabled:
                (imp.selectedFile == null ||
                imp.isImporting ||
                imp.importVariation == null),
            onPressed: () => _processAndNavigate(imp, par, nav, localVer, ciph),
            text: AppLocalizations.of(context)!.processPDF,
          ),
        FilledTextButton(
          isDark: false,
          text: AppLocalizations.of(context)!.cancel,
          onPressed: () => _handleCancel(imp, nav),
        ),
      ],
    );
  }

  void _clearSelectedFile(ImportProvider imp) {
    imp.clearSelectedFile();
    imp.clearSelectedFileName();
    imp.clearError();
  }

  Future<void> _processAndNavigate(
    ImportProvider imp,
    ParserProvider par,
    NavigationProvider nav,
    LocalVersionProvider localVer,
    CipherProvider ciph,
  ) async {
    final importedCipher = await imp.importText();
    if (importedCipher == null) {
      throw Exception('Failed to import text from PDF');
    }
    await par.parseCipher(importedCipher);
    nav.push(
      () => EditCipherScreen(
        cipherID: widget.cipherID,
        versionType: VersionType.import,
        versionID: widget.versionID,
      ),
      keepAlive: true,
      changeDetector: () =>
          localVer.hasUnsavedChanges || ciph.hasUnsavedChanges ,
      onChangeDiscarded: () {
        localVer.loadVersion(widget.versionID);
        ciph.loadCipher(widget.cipherID);
      },
    );
  }

  void _handleCancel(ImportProvider imp, NavigationProvider nav) {
    imp.clearCache();
    nav.attemptPop(context);
  }
}
