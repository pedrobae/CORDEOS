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

  bool isCloud = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollProvider = context.read<AutoScrollProvider>();

    isCloud = widget.cloudVersionID != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_scrollListener);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final isManualScroll =
        _scrollController.position.userScrollDirection != ScrollDirection.idle;

    if (isManualScroll && _scrollProvider.scrollModeEnabled) {
      _scrollProvider.stopAutoScroll();
    }

    // Update scroll index
    _scrollProvider.syncTabSectionFromViewport(
      _scrollController.position.viewportDimension,
    );
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
                      .getVersion(widget.localVersionID!)!
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
                        const SizedBox(height: 50),
                        // HEADER
                        _buildHeader(textTheme),
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
            final version = localVersionProvider.getVersion(
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
        final sectionKey = _scrollProvider.registerTabSection(index);
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

        _scrollProvider.setTabSectionLineCount(
          index,
          section.contentText.split('\n').length,
        );

        if (isAnnotation(trimmedCode)) {
          return AnnotationCard(
            key: sectionKey,
            sectionText: section.contentText,
            sectionType: section.contentType,
          );
        }

        return SectionCard(
          key: sectionKey,
          sectionType: section.contentType,
          sectionCode: trimmedCode,
          sectionText: section.contentText,
          sectionColor: section.contentColor,
        );
      },
    );
  }
}
