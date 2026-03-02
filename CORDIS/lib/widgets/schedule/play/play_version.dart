import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class PlayVersion extends StatefulWidget {
  final int? localVersionID;
  final String? cloudVersionID;

  const PlayVersion({super.key, this.localVersionID, this.cloudVersionID});

  @override
  State<PlayVersion> createState() => _PlayVersionState();
}

class _PlayVersionState extends State<PlayVersion> {
  late final ScrollController _scrollController;
  late final List<GlobalKey> sectionKeys = [];
  late final ValueNotifier<bool> _showTopBar = ValueNotifier(false);
  final _headerSectionKey = GlobalKey();
  bool isCloud = false;
  double _headerHeight = 0;
  DateTime _lastScrollUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    isCloud = widget.cloudVersionID != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSectionKeys();
      _calculateHeaderHeight();
      _scrollController.addListener(_scrollListener);
    });
  }

  void _initializeSectionKeys() {
    final lvp = context.read<LocalVersionProvider>();
    final cvp = context.read<CloudVersionProvider>();
    final layoutProvider = context.read<LayoutSettingsProvider>();

    final songStructure = isCloud
        ? cvp.getVersion(widget.cloudVersionID!)?.songStructure
        : lvp.cachedVersion(widget.localVersionID!)?.songStructure;

    if (songStructure == null) {
      return;
    }
    final filteredStructure = songStructure
        .where(
          (sectionCode) =>
              ((layoutProvider.showAnnotations || !isAnnotation(sectionCode)) &&
              (layoutProvider.showTransitions || !isTransition(sectionCode))),
        )
        .toList();

    sectionKeys.clear();
    for (int i = 0; i < filteredStructure.length; i++) {
      sectionKeys.add(GlobalKey());
    }
  }

  void _calculateHeaderHeight() {
    final headerContext = _headerSectionKey.currentContext;
    if (headerContext != null) {
      final box = headerContext.findRenderObject() as RenderBox?;
      if (box != null) {
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
    // Throttle to 50ms for smoother updates without jank
    final now = DateTime.now();
    if (now.difference(_lastScrollUpdate).inMilliseconds < 50) {
      // Always check critical boundaries even when throttled
      final offset = _scrollController.offset;
      final shouldShow = offset > _headerHeight && offset > 0;
      if (shouldShow != _showTopBar.value) {
        _showTopBar.value = shouldShow; // Update without expensive setState
      }
      return;
    }
    _lastScrollUpdate = now;

    final offset = _scrollController.offset;
    // Hide bar when at top, show when past header height
    final shouldShow = offset > _headerHeight && offset > 0;

    if (shouldShow != _showTopBar.value) {
      _showTopBar.value =
          shouldShow; // Direct ValueNotifier update = no full rebuild
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
            if (sectionKeys.isEmpty) {
              _initializeSectionKeys();
            }

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
                      ((layoutProvider.showAnnotations ||
                          !isAnnotation(sectionCode)) &&
                      (layoutProvider.showTransitions ||
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
                                      AppLocalizations.of(
                                        context,
                                      )!.songStructure,
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
                                          color: colorScheme
                                              .surfaceContainerLowest,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: StructureList(
                                      versionId:
                                          widget.localVersionID ??
                                          widget.cloudVersionID!,
                                      filteredStructure: filteredStructure,
                                      scrollController: _scrollController,
                                      sectionKeys: sectionKeys,
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
                ValueListenableBuilder<bool>(
                  valueListenable: _showTopBar,
                  builder: (context, showBar, child) {
                    return showBar
                        ? Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildStickyBar(
                              context,
                              colorScheme,
                              filteredStructure,
                            ),
                          )
                        : const SizedBox.shrink();
                  },
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

        return SectionCard(
          key: sectionKeys[index],
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 66,
            ),
            child: StructureList(
              versionId: widget.localVersionID ?? widget.cloudVersionID!,
              filteredStructure: filteredStructure,
              scrollController: _scrollController,
              sectionKeys: sectionKeys,
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
    );
  }
}
