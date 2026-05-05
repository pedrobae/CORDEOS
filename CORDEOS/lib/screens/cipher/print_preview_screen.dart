import 'dart:io';
import 'dart:math';

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
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
  final int? versionID;
  final int? playlistID;

  PrintPreviewScreen({super.key, this.versionID, this.playlistID}) {
    assert((versionID != null || playlistID != null));
  }

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final print = context.read<PrintingProvider>();

    final availableWidth =
        MediaQuery.sizeOf(context).width - 48; // Account for padding
    final pageAspectRatio = 1 / sqrt(2);
    final pageWidth = min(availableWidth, 600.0);
    final pageHeight = pageWidth / pageAspectRatio;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).viewPadding.top,
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      child:
          Selector6<
            TranspositionProvider,
            PlaylistProvider,
            CipherProvider,
            LocalVersionProvider,
            SectionProvider,
            PrintingProvider,
            ({
              Map<int, Cipher> ciphers,
              List<Version> versions,
              Map<int, Map<int, Section>> versionsSections,
              Map<int, String Function(String)> versionsTransposeChords,
              bool showChords,
              bool showLyrics,
              String fileName,
            })
          >(
            selector: (context, trans, play, ciph, localVer, sect, print) {
              final versionIDs = <int>[];
              String fileName = '';
              if (widget.versionID != null) {
                versionIDs.add(widget.versionID!);
              }

              if (widget.playlistID != null) {
                final playlist = play.getPlaylist(widget.playlistID!);

                if (playlist == null) {
                  throw Exception(
                    'Playlist not found for ID: ${widget.playlistID}',
                  );
                }

                fileName = playlist.name;

                for (final item in playlist.items) {
                  switch (item.type) {
                    case PlaylistItemType.version:
                      versionIDs.add(item.contentId!);
                      break;
                    case PlaylistItemType.flowItem:
                      //TODO-EXPORT FLOW ITEM
                      break;
                  }
                }
              }

              final versions = <Version>[];
              final ciphers = <int, Cipher>{};
              final versionsSections = <int, Map<int, Section>>{};
              final versionsTransposeChords = <int, String Function(String)>{};

              for (final versionID in versionIDs) {
                final version = localVer.getVersion(versionID);
                if (version == null) {
                  debugPrint('Version not found for ID: $versionID');
                  continue;
                }
                final cipher = ciph.getCipher(version.cipherID);
                if (cipher == null) {
                  debugPrint('Cipher not found for ID: $versionID');
                  continue;
                }
                if (widget.playlistID == null) {
                  fileName = cipher.title;
                }
                final sections = sect.getSections(versionID);
                final transposeChord = (String chord) => trans.transposeChord(
                  chord,
                  cipher.musicKey,
                  version.transposedKey,
                );

                versions.add(version);
                ciphers[versionID] = cipher;
                versionsSections[versionID] = sections;
                versionsTransposeChords[versionID] = transposeChord;
              }

              return (
                versionsTransposeChords: versionsTransposeChords,
                ciphers: ciphers,
                versions: versions,
                versionsSections: versionsSections,
                showChords: print.showChords,
                showLyrics: print.showLyrics,
                fileName: fileName,
              );
            },
            builder: (context, s, child) {
              print.tokenize(
                versionsTransposeChords: s.versionsTransposeChords,
                context: context,
                ciphers: s.ciphers,
                versions: s.versions,
                versionsSections: s.versionsSections,
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
                      final snapshots = print.buildPreviewSnapshot(
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

                      final pages = print.layoutPages(
                        snapshots,
                        pageHeight,
                        layoutSettings.sectionMaxWidth,
                      );

                      return Column(
                        children: [
                          _buildAppBar(snapshots, pages, pageWidth, s.fileName),
                          _buildControlBar(),
                          Expanded(
                            child: _buildPreviewArea(
                              snapshots,
                              pages,
                              availableWidth,
                              pageHeight,
                              pageCtx,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildAppBar(
    List<PrintPreviewSnapshot> snapshots,
    List<PageLayout> pages,
    double pageWidth,
    String name,
  ) {
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
              try {
                setState(() {
                  _isGenerating = true;
                });
                final pdfBytes = await context
                    .read<PrintingProvider>()
                    .generatePDF(pages, snapshots, pageWidth);

                // Save PDF to documents directory
                final dir = await getApplicationDocumentsDirectory();
                final fileName = '${name}.pdf';
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

  Widget _buildPreviewArea(
    List<PrintPreviewSnapshot> snapshots,
    List<PageLayout> pages,
    double availableWidth,
    double pageHeight,
    PageContext pageCtx,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.shadow,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          spacing: 16,
          children: [
            for (int pageIndex = 0; pageIndex < pages.length; pageIndex++)
              SizedBox(
                width: availableWidth,
                height: pageHeight,
                child: CustomPaint(
                  painter: PagePreviewPainter(
                    snapshots: snapshots,
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
      ),
    );
  }
}
