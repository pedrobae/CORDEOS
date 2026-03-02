import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/cipher/parser_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/import_provider.dart';
import 'package:flutter/material.dart';

class ImportPdfScreen extends StatefulWidget {
  const ImportPdfScreen({super.key});

  @override
  State<ImportPdfScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends State<ImportPdfScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ImportProvider>().setImportType(ImportType.pdf);
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
    return Consumer5<
      ImportProvider,
      ParserProvider,
      NavigationProvider,
      LocalVersionProvider,
      CipherProvider
    >(
      builder:
          (
            context,
            importProvider,
            parserProvider,
            navigationProvider,
            localVersionProvider,
            cipherProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppLocalizations.of(context)!.importFromPDF,
                  style: textTheme.titleMedium,
                ),
                leading: BackButton(
                  onPressed: () {
                    navigationProvider.attemptPop(context);
                  },
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selected file display
                    if (importProvider.selectedFile != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            color: colorScheme.onSurface,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
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
                                    importProvider.selectedFileName!,
                                    style: textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    importProvider.fileSize ?? '',
                                    style: textTheme.bodySmall,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
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
                              onTap: () {
                                // Clear selected file
                                importProvider.clearSelectedFile();
                                importProvider.clearSelectedFileName();
                                importProvider.clearError();
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // File selection button
                      FilledTextButton(
                        onPressed: () {
                          importProvider.isImporting ? null : _pickPdfFile();
                        },
                        text: AppLocalizations.of(context)!.selectPDFFile,
                        isDark: true,
                      ),
                    ],

                    const SizedBox(height: 16),

                    /// HAS COLUMNS TOGGLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.hasColumns,
                          style: textTheme.titleMedium,
                        ),
                        Switch(
                          value:
                              importProvider.importVariation ==
                              ImportVariation.pdfWithColumns,
                          onChanged: (value) {
                            importProvider.setImportVariation(
                              value
                                  ? ImportVariation.pdfWithColumns
                                  : ImportVariation.pdfNoColumns,
                            );
                          },
                        ),
                      ],
                    ),

                    // Error display
                    if (importProvider.error != null)
                      Card(
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  importProvider.error!,
                                  style: textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Import instructions and tips
                    Container(
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
                    ),

                    // Process button
                    Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (parserProvider.isParsing) ...[
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.surfaceContainer,
                          ),
                        ] else ...[
                          FilledTextButton(
                            isDark: true,
                            isDisabled:
                                (importProvider.selectedFile == null ||
                                importProvider.isImporting ||
                                importProvider.importVariation == null),
                            onPressed: () async {
                              await importProvider.importText();

                              await parserProvider.parseCipher(
                                importProvider.importedCipher!,
                              );

                              // Navigate to parsing screen
                              navigationProvider.push(
                                EditCipherScreen(
                                  cipherID: -1,
                                  versionType: VersionType.import,
                                  versionID: -1,
                                ),
                                changeDetector: () {
                                  return localVersionProvider.hasUnsavedChanges ||
                                         cipherProvider.hasUnsavedChanges;
                                },
                                showBottomNavBar: true,
                              );
                            },
                            text: AppLocalizations.of(context)!.processPDF,
                          ),
                        ],

                        // Cancel button
                        FilledTextButton(
                          isDark: false,
                          text: AppLocalizations.of(context)!.cancel,
                          onPressed: () {
                            importProvider.clearCache();
                            navigationProvider.attemptPop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
