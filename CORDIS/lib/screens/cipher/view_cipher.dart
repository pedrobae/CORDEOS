import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';
import 'package:cordis/widgets/ciphers/transposer.dart';
import 'package:cordis/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:cordis/widgets/settings/content_filters.dart';
import 'package:cordis/widgets/settings/style_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';

class ViewCipherScreen extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;

  const ViewCipherScreen({
    super.key,
    required this.cipherID,
    this.versionID,
    required this.versionType,
  });

  @override
  State<ViewCipherScreen> createState() => _ViewCipherScreenState();
}

class _ViewCipherScreenState extends State<ViewCipherScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _setOriginalKey();
    });
  }

  void _setOriginalKey() {
    final tp = context.read<TranspositionProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final cipherProvider = context.read<CipherProvider>();

    final String originalKey;
    final String? transposedKey;
    // Set original key for transposer
    if (widget.versionType == VersionType.cloud) {
      final version = cloudVersionProvider.getVersion(widget.versionID)!;
      originalKey = version.originalKey;
      transposedKey = version.transposedKey;
    } else {
      final cipher = cipherProvider.getCipher(widget.cipherID!);

      final version = localVersionProvider.cachedVersion(widget.versionID);
      originalKey = cipher!.musicKey;
      transposedKey = version?.transposedKey;
    }
    tp.setOriginalKey(originalKey);
    tp.setTransposedKey(transposedKey);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      CipherProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      LayoutSettingsProvider,
      TranspositionProvider
    >(
      builder: (context, cp, lvp, cvp, sp, lsp, tp, child) {
        final scrollProvider = context.read<AutoScrollProvider>();
        // Handle loading states
        if (cp.isLoading || lvp.isLoading || cvp.isLoading || sp.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Carregando...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Handle error states
        if (cp.error != null ||
            lvp.error != null ||
            cvp.error != null ||
            sp.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${cp.error ?? lvp.error ?? cvp.error ?? sp.error}',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        String title;
        String author;
        int bpm;
        Duration duration;
        List<String> songStructure;

        (
          title,
          author,
          bpm,
          duration,
          songStructure,
        ) = widget.versionID is String
            ? () {
                final versionDto = cvp.getVersion(widget.versionID)!;
                return (
                  versionDto.title,
                  versionDto.author,
                  versionDto.bpm,
                  Duration(seconds: versionDto.duration),
                  songStructure = versionDto.songStructure,
                );
              }()
            : () {
                final cipher = cp.getCipher(widget.cipherID!);
                final version = lvp.cachedVersion(widget.versionID);
                return (
                  cipher?.title ?? '',
                  cipher?.author ?? '',
                  version?.bpm ?? 0,
                  version?.duration ?? Duration.zero,
                  songStructure = version?.songStructure ?? [],
                );
              }();

        final filteredStructure = <String>[];
        for (var sectionCode in songStructure) {
          if (!lsp.showAnnotations && isAnnotation(sectionCode)) {
            continue;
          }
          if (!lsp.showTransitions && isTransition(sectionCode)) {
            continue;
          }
          filteredStructure.add(sectionCode);
        }

        final sectionCardList = filteredStructure.asMap().entries.map((entry) {
          String trimmedCode = entry.value.trim();
          final section = sp.getSection(widget.versionID, trimmedCode);

          if (section == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (section.contentText.isEmpty) {
            return const SizedBox.shrink();
          }
          
          if (scrollProvider.sectionKeys[entry.key] == null) {
            scrollProvider.sectionKeys[entry.key] = GlobalKey();
          }
          final key = scrollProvider.sectionKeys[entry.key]!;

          if (isAnnotation(trimmedCode)) {
            return AnnotationCard(
              key: key,
              sectionText: section.contentText,
              sectionType: section.contentType,
            );
          } else {
            return SectionCard(
              key: key,
              sectionType: section.contentType,
              sectionCode: trimmedCode,
              sectionText: section.contentText,
              sectionColor: section.contentColor,
            );
          }
        }).toList();

        // Add space at the end of the list for better scrolling
        sectionCardList.add(SizedBox(height: 200));

        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            // ACTIONS
            Row(
              children: [
                if (widget.versionType == VersionType.local)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.read<NavigationProvider>().push(
                        EditCipherScreen(
                          cipherID: widget.cipherID,
                          versionID: widget.versionID,
                          versionType: widget.versionType,
                        ),
                        changeDetector: () {
                          return widget.versionID is String
                              ? false
                              : (lvp.hasUnsavedChanges ||
                                    cp.hasUnsavedChanges ||
                                    sp.hasUnsavedChanges);
                        },
                        showBottomNavBar: true,
                      );
                    },
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: _showStyleSettings(),
                ),
                IconButton(
                  icon: Icon(Icons.filter_alt),
                  onPressed: _showFilters(),
                ),
                const Spacer(),
                Transposer(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    context.read<NavigationProvider>().attemptPop(context);
                  },
                ),
              ],
            ),

            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    spacing: 16,
                    children: [
                      // HEADER
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.by} $author',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 8.0),
                          // info
                          Row(
                            spacing: 16.0,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.keyWithPlaceholder(
                                  tp.transposedKey ?? tp.originalKey,
                                ),
                                style: textTheme.bodySmall,
                              ),
                              bpm != 0
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.bpmWithPlaceholder(bpm.toString()),
                                      style: textTheme.bodySmall,
                                    )
                                  : Text('-'),
                              duration != Duration.zero
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.durationWithPlaceholder(
                                        DateTimeUtils.formatDuration(duration),
                                      ),
                                      style: textTheme.bodySmall,
                                    )
                                  : Text('-'),
                            ],
                          ),
                        ],
                      ),

                      // SONG STRUCTURE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.songStructure,
                            style: textTheme.titleMedium,
                          ),
                          StructureList(
                            versionId: widget.versionID,
                            filteredStructure: filteredStructure,
                            scrollController: scrollController,
                          ),
                        ],
                      ),

                      // SECTIONS
                      MasonryGridView.count(
                        crossAxisCount: lsp.columnCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        itemCount: sectionCardList.length,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) => sectionCardList[index],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final sectionProvider = context.read<SectionProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();

    switch (widget.versionType) {
      case VersionType.import:
      case VersionType.brandNew:
        break;
      case VersionType.local:
      case VersionType.playlist:
        if (widget.versionID != null) {
          await sectionProvider.loadSectionsOfVersion(widget.versionID);
        }
        break;
      case VersionType.cloud:
        if (widget.versionID != null) {
          final version = cloudVersionProvider.getVersion(widget.versionID);
          sectionProvider.setNewSectionsInCache(
            widget.versionID,
            version!.toDomain().sections!,
          );
        }
        break;
    }
  }

  VoidCallback _showStyleSettings() {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return BottomSheet(
            onClosing: () {},
            builder: (context) => const StyleSettings(),
          );
        },
      );
    };
  }

  VoidCallback _showFilters() {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return BottomSheet(
            onClosing: () {},
            builder: (context) {
              return const ContentFilters();
            },
          );
        },
      );
    };
  }
}
