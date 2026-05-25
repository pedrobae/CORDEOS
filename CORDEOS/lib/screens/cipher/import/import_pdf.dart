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
import 'package:cordeos/screens/cipher/import/batch_staging.dart';
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
  List<ImportFile> _files = [];

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

  /// Opens file picker and allows user to select a PDF file
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
      );

      // User selected a file
      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          setState(() {
            _files.add(
              ImportFile(
                importType: ImportType.pdf,
                parsingStrategy: ParsingStrategy.pdfFormatting,
                importVariation: ImportVariation.pdfNoColumns,
                path: file.path,
                name: file.name,
                size: file.size,
              ),
            );
          });
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
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectFileButton(),
            _buildFiles(),
            _buildImportInstructions(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();

    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.importFromPDF,
        style: textTheme.titleMedium,
      ),
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
    );
  }

  Widget _buildFiles() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: colorScheme.onSurface, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 24,
                  color: colorScheme.shadow,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _parseFileSize(file.size),
                          style: textTheme.bodySmall,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.view_column),
                Switch(
                  value: file.importVariation == ImportVariation.pdfWithColumns,
                  onChanged: (value) {
                    setState(() {
                      file.importVariation = value
                          ? ImportVariation.pdfWithColumns
                          : ImportVariation.pdfNoColumns;
                    });
                  },
                ),
                GestureDetector(
                  onTap: () => _clearSelectedFile(index),
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
        },
      ),
    );
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
            AppLocalizations.of(context)!.pdfImportInstructions,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector<ParserProvider, bool>(
      selector: (context, par) {
        return par.isParsing;
      },
      builder: (context, isParsing, child) {
        return Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isParsing)
              CircularProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainer,
              )
            else
              FilledTextButton(
                isDark: true,
                onPressed: _processAndNavigate(),
                text: AppLocalizations.of(context)!.processPDF,
              ),
            FilledTextButton(
              isDark: false,
              text: AppLocalizations.of(context)!.cancel,
              onPressed: () => _handleCancel(),
            ),
          ],
        );
      },
    );
  }

  void _clearSelectedFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  VoidCallback _processAndNavigate() {
    return () async {
      final imp = context.read<ImportProvider>();
      final par = context.read<ParserProvider>();
      final ciph = context.read<CipherProvider>();
      final localVer = context.read<LocalVersionProvider>();
      final sect = context.read<SectionProvider>();
      final nav = context.read<NavigationProvider>();

      final imports = <ParsingCipher>[];
      for (final file in _files) {
        imports.add(await imp.importFromPDF(file));
      }
      final versionIDs = <int>[];
      for (final import in imports) {
        final song = await par.parseCipher(import);
        if (song != null) {
          if (widget.versionID != -1) {
            // MERGE SECTIONS WITH EXISTING SONG
            final sections = song.sections.map(
              (key, value) => MapEntry(key, value.toDomain()),
            );
            for (final section in sections.values) {
              final newKey = sect.cacheAddSection(widget.versionID, section);
              localVer.addSectionToStruct(widget.versionID, newKey);
            }
            versionIDs.add(widget.versionID);
          } else {
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
      }

      if (versionIDs.length == 1) {
        nav.pop;
        if (widget.versionID == -1) {
          nav.push(
            () => EditCipherScreen(
              cipherID: widget.cipherID,
              versionID: widget.versionID,
              versionType: VersionType.local,
            ),
            keepAlive: true,
            changeDetector: () =>
                localVer.hasUnsavedChanges || ciph.hasUnsavedChanges,
            onChangeDiscarded: () {
              localVer.loadVersion(widget.versionID);
              ciph.loadCipher(widget.cipherID);
            },
          );
        }
      } else {
        nav.push(
          () => BatchImportStaging(versionIDs: versionIDs),
          keepAlive: true,
          showBottomNavBar: true,
          onPopCallback: () {
            par.clearCache();
          },
        );
      }
    };
  }

  void _handleCancel() {
    final nav = context.read<NavigationProvider>();
    nav.attemptPop(context);
  }
}
