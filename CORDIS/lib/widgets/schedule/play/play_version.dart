import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/widgets/schedule/play/auto_scroll_indicator.dart';
import 'package:flutter/material.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/cipher/section.dart';
import 'package:flutter/rendering.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';

import 'package:cordis/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PlayVersion extends StatefulWidget {
  final int? localVersionID;
  final String? cloudVersionID;

  const PlayVersion({super.key, this.localVersionID, this.cloudVersionID});

  @override
  State<PlayVersion> createState() => _PlayVersionState();
}

class _PlayVersionState extends State<PlayVersion> {
  late final ScrollController _scrollController;
  late final AutoScrollProvider _scrollProvider;
  late final ValueNotifier<bool> _showTopBar = ValueNotifier(false);
  final _headerSectionKey = GlobalKey();
  double _headerHeight = 0;
  bool isCloud = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollProvider = context.read<AutoScrollProvider>();

    isCloud = widget.cloudVersionID != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
      _scrollController.addListener(_scrollListener);
    });
  }

  void _calculateHeaderHeight() {
    final headerContext = _headerSectionKey.currentContext;
    if (headerContext != null) {
      final box = headerContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _headerHeight = box.size.height + kToolbarHeight + 10;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showTopBar.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Always check critical boundaries even when throttled
    final offset = _scrollController.offset;
    final shouldShow = offset > _headerHeight && offset > 0;
    if (shouldShow != _showTopBar.value) {
      _showTopBar.value = shouldShow; // Update without expensive setState
    }

    final isManualScroll =
        _scrollController.position.userScrollDirection != ScrollDirection.idle;

    if (isManualScroll && _scrollProvider.scrollModeEnabled) {
      _scrollProvider.stopAutoScroll();
    }

    // Update scroll index
    final sectionIndex = _scrollProvider.calcCurrentIndex(
      _scrollController.position.viewportDimension,
    );
    if (sectionIndex != _scrollProvider.currentSectionIndex.value) {
      _scrollProvider.currentSectionIndex.value = sectionIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer5<
      CipherProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      LayoutSettingsProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            localVersionProvider,
            cloudVersionProvider,
            sectionProvider,
            layoutProvider,
            child,
          ) {
            // LOADING STATE
            if (localVersionProvider.isLoading ||
                cloudVersionProvider.isLoading ||
                sectionProvider.isLoading ||
                (isCloud
                    ? widget.cloudVersionID == null
                    : widget.localVersionID == null)) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final songStructure = isCloud
                ? cloudVersionProvider
                      .getVersion(widget.cloudVersionID!)!
                      .songStructure
                : localVersionProvider
                      .cachedVersion(widget.localVersionID!)!
                      .songStructure;

            final filteredStructure = songStructure
                .where(
                  (sectionCode) =>
                      ((layoutProvider.layoutFilters[LayoutFilter
                              .annotations]! ||
                          !isAnnotation(sectionCode)) &&
                      (layoutProvider.layoutFilters[LayoutFilter
                              .transitions]! ||
                          !isTransition(sectionCode))),
                )
                .toList();

            return Stack(
              children: [
                // MAIN SCROLLABLE CONTENT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        const SizedBox(height: 8),
                        // HEADER
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            _buildHeader(textTheme),
                            // SONG STRUCTURE
                            Column(
                              spacing: 4,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    AppLocalizations.of(context)!.songStructure,
                                    style: textTheme.titleMedium,
                                  ),
                                ),
                                Container(
                                  key: _headerSectionKey,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    border: Border.fromBorderSide(
                                      BorderSide(
                                        color:
                                            colorScheme.surfaceContainerLowest,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: StructureList(
                                    versionId:
                                        widget.localVersionID ??
                                        widget.cloudVersionID!,
                                    filteredStructure: filteredStructure,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // SECTION CARDS GRID
                        _buildSectionGrid(
                          sectionProvider,
                          layoutProvider,
                          cloudVersionProvider,
                          filteredStructure,
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ),

                // SCROLL-CONDITIONAL TOP SONG STRUCTURE BAR
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showTopBar,
                    builder: (context, showBar, child) {
                      return Visibility(
                        visible: showBar,
                        maintainState: true,
                        child: child!,
                      );
                    },
                    child: _buildStickyBar(
                      context,
                      colorScheme,
                      filteredStructure,
                    ),
                  ),
                ),

                // AUTO SCROLL INDICATOR
                Positioned(
                  bottom: 66,
                  right: 16,
                  child: Consumer<AutoScrollProvider>(
                    builder: (context, scrollProvider, _) {
                      return Visibility(
                        visible: scrollProvider.scrollModeEnabled,
                        maintainState: true,
                        child: AutoScrollIndicator(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    final cipherProvider = context.read<CipherProvider>();
    final localVersionProvider = context.read<LocalVersionProvider>();
    final cloudVersionProvider = context.read<CloudVersionProvider>();

    String title;
    String key;
    int bpm;
    Duration duration;

    (title, key, bpm, duration) = isCloud
        ? () {
            final version = cloudVersionProvider.getVersion(
              widget.cloudVersionID!,
            )!;
            return (
              version.title,
              version.transposedKey ?? version.originalKey,
              version.bpm,
              Duration(milliseconds: version.duration),
            );
          }()
        : () {
            final version = localVersionProvider.cachedVersion(
              widget.localVersionID!,
            )!;
            final cipher = cipherProvider.getCipher(version.cipherId);
            return (
              cipher?.title ?? '',
              version.transposedKey ?? cipher?.musicKey ?? '',
              version.bpm,
              version.duration,
            );
          }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(title, style: textTheme.titleMedium),
        Row(
          spacing: 16.0,
          children: [
            Text(
              AppLocalizations.of(context)!.keyWithPlaceholder(key),
              style: textTheme.bodyMedium,
            ),
            Text(
              AppLocalizations.of(context)!.bpmWithPlaceholder(bpm),
              style: textTheme.bodyMedium,
            ),
            Text(
              '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(duration)}',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionGrid(
    SectionProvider sectionProvider,
    LayoutSettingsProvider layoutProvider,
    CloudVersionProvider cloudVersionProvider,
    List<String> filteredStructure,
  ) {
    return MasonryGridView.count(
      crossAxisCount: layoutProvider.columnCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: filteredStructure.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final trimmedCode = filteredStructure[index].trim();
        final section = isCloud
            ? () {
                final sectionMap = cloudVersionProvider
                    .getVersion(widget.cloudVersionID!)!
                    .sections[trimmedCode]!;
                return Section.fromFirestore(sectionMap);
              }()
            : sectionProvider.getSection(widget.localVersionID!, trimmedCode);

        if (section == null) {
          return const SizedBox.shrink();
        }

        if (isAnnotation(trimmedCode)) {
          return AnnotationCard(
            sectionText: section.contentText,
            sectionType: section.contentType,
          );
        }
        // Create key if it doesn't exist
        final scrollProvider = Provider.of<AutoScrollProvider>(
          context,
          listen: false,
        );
        if (scrollProvider.sectionKeys[index] == null) {
          scrollProvider.sectionKeys[index] = GlobalKey();
        }
        scrollProvider.sectionLineCounts[index] = section.contentText
            .split('\n')
            .length;

        return SectionCard(
          key: scrollProvider.sectionKeys[index],
          sectionType: section.contentType,
          sectionCode: trimmedCode,
          sectionText: section.contentText,
          sectionColor: section.contentColor,
        );
      },
    );
  }

  Widget _buildStickyBar(
    BuildContext context,
    ColorScheme colorScheme,
    List<String> filteredStructure,
  ) {
    return SizedBox(
      height: 66,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.surfaceContainerHigh,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: colorScheme.surfaceContainerHigh,
                    width: 1,
                  ),
                ),
              ),
              child: StructureList(
                versionId: widget.localVersionID ?? widget.cloudVersionID!,
                filteredStructure: filteredStructure,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color: colorScheme.surfaceContainerHigh,
                  width: 1,
                ),
                bottom: BorderSide(
                  color: colorScheme.surfaceContainerHigh,
                  width: 1,
                ),
                top: BorderSide(
                  color: colorScheme.surfaceContainerHigh,
                  width: 1,
                ),
              ),
            ),
            height: 66,
            width: 66,
          ),
        ],
      ),
    );
  }
}
