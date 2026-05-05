import 'dart:io';
import 'dart:math';

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/ciphers/print/page_preview_painter.dart';
import 'package:cordeos/widgets/ciphers/print/sheet_print_filters.dart';
import 'package:cordeos/widgets/ciphers/print/sheet_print_layout.dart';
import 'package:cordeos/widgets/ciphers/print/sheet_print_style.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class PrintPreviewScreen extends StatefulWidget {
  final int versionID;

  const PrintPreviewScreen({super.key, required this.versionID});

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  List<PageLayout> pages = [];
  PrintPreviewSnapshot? snapshot;
  double pageWidth = 0;

  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).viewPadding.top,
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        children: [
          _buildAppBar(),
          _buildControlBar(),
          Expanded(child: _buildPreviewArea()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => nav.pop(),
        ),
        const Spacer(),
        Text(l10n.printPreview, style: textTheme.titleMedium),
        const Spacer(),
        if (_isGenerating) ...[
          CircularProgressIndicator(),
        ] else ...[
          IconButton(
            onPressed: () async {
              if (snapshot != null) {
                try {
                  setState(() {
                    _isGenerating = true;
                  });
                  final pdfBytes = await context
                      .read<PrintingProvider>()
                      .generatePDF(pages, snapshot!, pageWidth);

                  // Save PDF to documents directory
                  final dir = await getApplicationDocumentsDirectory();
                  final fileName = '${snapshot!.filename}.pdf';
                  final file = File('${dir.path}/$fileName');
                  await file.writeAsBytes(pdfBytes);

                  // Open PDF with default viewer
                  await OpenFile.open(file.path);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error generating PDF: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isGenerating = false;
                    });
                  }
                }
              }
            },
            icon: const Icon(Icons.print),
          ),
        ],
      ],
    );
  }

  Widget _buildControlBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              context: context,
              isScrollControlled: true,
              builder: (context) => PrintFilters(),
            );
          },
          icon: const Icon(Icons.filter_list),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              context: context,
              isScrollControlled: true,
              builder: (context) => PrintLayout(),
            );
          },
          icon: const Icon(Icons.format_paint_rounded),
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              context: context,
              isScrollControlled: true,
              builder: (context) => PrintStyle(),
            );
          },
          icon: const Icon(Icons.text_fields),
        ),
      ],
    );
  }

  Widget _buildPreviewArea() {
    final colorScheme = Theme.of(context).colorScheme;

    final print = context.read<PrintingProvider>();

    final availableWidth =
        MediaQuery.sizeOf(context).width - 48; // Account for padding
    final pageAspectRatio = 1 / sqrt(2);
    pageWidth = min(availableWidth, 600.0);
    final pageHeight = pageWidth / pageAspectRatio;

    return Container(
      color: colorScheme.shadow,
      child:
          Selector5<
            TranspositionProvider,
            CipherProvider,
            LocalVersionProvider,
            SectionProvider,
            PrintingProvider,
            ({
              String Function(String) transpose,
              Cipher cipher,
              Version version,
              Map<int, Section> sections,
              bool showChords,
            })
          >(
            selector: (context, trans, ciph, localVer, sect, print) {
              final version = localVer.getVersion(widget.versionID);
              if (version == null) {
                throw Exception(
                  'Version not found for ID: ${widget.versionID}',
                );
              }

              final cipher = ciph.getCipher(version.cipherID);
              if (cipher == null) {
                throw Exception('Cipher not found for ID: ${version.cipherID}');
              }
              final sections = sect.getSections(widget.versionID);
              final transposeChord = (String chord) => trans.transposeChord(
                chord,
                cipher.musicKey,
                version.transposedKey,
              );
              return (
                transpose: transposeChord,
                cipher: cipher,
                version: version,
                sections: sections,
                showChords: print.showChords,
              );
            },
            builder: (context, s, child) {
              print.tokenize(
                transposeChord: s.transpose,
                context: context,
                cipher: s.cipher,
                version: s.version,
                sections: s.sections,
              );

              return Selector<
                PrintingProvider,
                ({
                  double sectionMaxWidth,
                  double lineBreakSpacing,
                  double chordLyricSpacing,
                  double minChordSpacing,
                  double lineSpacing,
                  double letterSpacing,
                  double margin,
                  double columnGap,
                  double sectionSpacing,
                  double headerGap,
                  double fontSize,
                  String fontFamily,
                })
              >(
                selector: (context, print) {
                  final sectionMaxWidth =
                      (pageWidth -
                          (print.margin * 2) -
                          ((print.columnCount - 1) * print.columnGap)) /
                      print.columnCount;

                  return (
                    sectionMaxWidth: sectionMaxWidth,
                    lineBreakSpacing: print.heightSpacing * 2,
                    chordLyricSpacing: print.heightSpacing,
                    minChordSpacing: print.minChordSpacing,
                    lineSpacing: print.heightSpacing,
                    letterSpacing: print.letterSpacing,
                    fontSize: print.fontSize,
                    fontFamily: print.fontFamily,
                    margin: print.margin,
                    columnGap: print.columnGap,
                    sectionSpacing: print.sectionSpacing,
                    headerGap: print.headerGap,
                  );
                },
                builder: (context, layoutSettings, child) {
                  print.calculatePositions(layoutSettings.sectionMaxWidth);

                  return Selector<
                    PrintingProvider,
                    ({
                      bool showMetadata,
                      bool showRepeatSections,
                      bool showAnnotations,
                      bool showSongMap,
                      bool showSectionLabels,
                      bool showBpm,
                      bool showDuration,
                      Color lyricColor,
                      Color chordColor,
                      Color metadataColor,
                    })
                  >(
                    selector: (context, print) => (
                      showMetadata: print.showHeader,
                      showRepeatSections: print.showRepeatSections,
                      showAnnotations: print.showAnnotations,
                      showSongMap: print.showSongMap,
                      showSectionLabels: print.showSectionLabels,
                      showBpm: print.showBpm,
                      showDuration: print.showDuration,
                      lyricColor: print.lyricColor,
                      chordColor: print.chordColor,
                      metadataColor: print.headerColor,
                    ),
                    builder: (context, buildSettings, child) {
                      snapshot = print.buildPreviewSnapshot(
                        layoutSettings.sectionMaxWidth,
                      );

                      final pageCtx = PageContext(
                        pageWidth: pageWidth,
                        pageHeight: pageHeight,
                        margin: print.margin,
                        columnGap: print.columnGap,
                        sectionSpacing: print.sectionSpacing,
                        columnCount: print.columnCount,
                      );

                      pages = print.layoutPages(
                        snapshot!,
                        pageHeight,
                        layoutSettings.sectionMaxWidth,
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          spacing: 16,
                          children: [
                            for (
                              int pageIndex = 0;
                              pageIndex < pages.length;
                              pageIndex++
                            )
                              SizedBox(
                                width: availableWidth,
                                height: pageHeight,
                                child: CustomPaint(
                                  painter: PagePreviewPainter(
                                    snapshot: snapshot!,
                                    pages: pages,
                                    pageIndex: pageIndex,
                                    ctx: pageCtx,
                                    pageColor: Colors.white,
                                    shadowColor: Colors.black26,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }
}
