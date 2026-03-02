import 'dart:math';

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/common/custom_reorderable_delayed.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/viewer/version_card_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

class PlaylistVersionCard extends StatefulWidget {
  final int playlistId;
  final dynamic versionId;
  final int index;
  final int itemId;

  const PlaylistVersionCard({
    super.key,
    required this.playlistId,
    required this.index,
    required this.versionId,
    required this.itemId,
  });

  @override
  State<PlaylistVersionCard> createState() => _PlaylistVersionCardState();
}

class _PlaylistVersionCardState extends State<PlaylistVersionCard> {
  @override
  void initState() {
    super.initState();
    // Pre-load cipher data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final versionProvider = context.read<LocalVersionProvider>();
      final cloudVersionProvider = context.read<CloudVersionProvider>();
      final sectionProvider = context.read<SectionProvider>();
      final cipherProvider = context.read<CipherProvider>();

      // Ensure cipher is loaded for local versions
      if (widget.versionId is int) {
        await cipherProvider.loadCipherOfVersion(widget.versionId);
      }

      // Ensure the specific version is loaded
      if (widget.versionId is String &&
          !cloudVersionProvider.versions.containsKey(widget.versionId)) {
        throw Exception(
          'Cloud version with id ${widget.versionId} not found in cache',
        );
      } else {
        await versionProvider.loadVersion(widget.versionId);
        await sectionProvider.loadSectionsOfVersion(widget.versionId);
      }
    });
  }

  void _onReorder(
    BuildContext context,
    List<String> songStructure,
    int oldIndex,
    int newIndex,
  ) {
    // Create updated song structure
    final updatedStructure = List<String>.from(songStructure);
    if (newIndex > oldIndex) newIndex--;
    final item = updatedStructure.removeAt(oldIndex);
    updatedStructure.insert(newIndex, item);

    // Persist to database
    context.read<LocalVersionProvider>().cacheSongStructure(
      widget.versionId,
      updatedStructure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer4<
      LocalVersionProvider,
      CipherProvider,
      CloudVersionProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            versionProvider,
            cipherProvider,
            cloudVersionProvider,
            navigationProvider,
            child,
          ) {
            dynamic version;
            bool isCloud;

            if (widget.versionId is String) {
              version = cloudVersionProvider.getVersion(widget.versionId);
              isCloud = true;
            } else {
              version = versionProvider.cachedVersion(widget.versionId);
              isCloud = false;
            }

            // If version is not cached yet, show loading indicator
            if (version == null) {
              return Center(child: CircularProgressIndicator());
            }

            Cipher? cipher = isCloud
                ? null
                : cipherProvider.getCipher(version.cipherId);

            if (!isCloud && cipher == null) {
              return Center(child: CircularProgressIndicator());
            }

            final List<String> songStructure = version.songStructure;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.surfaceContainerLowest),
                borderRadius: BorderRadius.circular(0),
              ),
              padding: const EdgeInsets.only(left: 8),
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomReorderableDelayed(
                    delay: Duration(milliseconds: 100),
                    index: widget.index,
                    child: Icon(Icons.drag_indicator),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          start: BorderSide(
                            color: colorScheme.surfaceContainerLowest,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  spacing: 4,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCloud ? version.title : cipher!.title,
                                      style: theme.textTheme.titleMedium,
                                      softWrap: true,
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${AppLocalizations.of(context)!.musicKey}: ',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            Text(
                                              isCloud
                                                  ? (version.transposedKey ??
                                                        version.originalKey)
                                                  : (version.transposedKey ??
                                                        cipher!.musicKey),
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${AppLocalizations.of(context)!.bpm}: ',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            Text(
                                              version.bpm.toString(),
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          DateTimeUtils.formatDuration(
                                            isCloud
                                                ? Duration(
                                                    seconds: version.duration,
                                                  )
                                                : version.duration,
                                          ),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    // REORDERABLE SECTION CHIPS
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 25,
                                      ),
                                      child: ReorderableListView.builder(
                                        shrinkWrap: true,
                                        proxyDecorator:
                                            (child, index, animation) =>
                                                Material(
                                                  type:
                                                      MaterialType.transparency,
                                                  child: child,
                                                ),
                                        buildDefaultDragHandles: false,
                                        physics: const ClampingScrollPhysics(),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: songStructure.length,
                                        onReorder: (oldIndex, newIndex) =>
                                            _onReorder(
                                              context,
                                              songStructure,
                                              oldIndex,
                                              newIndex,
                                            ),
                                        itemBuilder: (_, index) {
                                          final sectionCode =
                                              songStructure[index];
                                          final Section section = isCloud
                                              ? Section.fromFirestore(
                                                  version
                                                      .sections[sectionCode]!,
                                                )
                                              : version.sections![sectionCode];
                                          // To ensure unique keys for identical section codes,
                                          final occurrenceIndex = songStructure
                                              .take(index + 1)
                                              .where(
                                                (code) => code == sectionCode,
                                              )
                                              .length;

                                          // Painter for sections with large codes
                                          final textPainter = TextPainter(
                                            text: TextSpan(
                                              text: sectionCode,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            maxLines: 1,
                                            textDirection: TextDirection.ltr,
                                          )..layout();

                                          return CustomReorderableDelayed(
                                            delay: Duration(milliseconds: 100),
                                            key: ValueKey(
                                              'cipher_${widget.versionId}_section_${sectionCode}_occurrence_$occurrenceIndex',
                                            ),
                                            index: index,
                                            child: Container(
                                              height: 25,
                                              width: max(
                                                25,
                                                textPainter.size.width + 8,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                                color: section.contentColor
                                                    .withValues(alpha: 0.8),
                                                border: BoxBorder.all(
                                                  color: section.contentColor,
                                                  width: 2,
                                                ),
                                              ),
                                              margin: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  strutStyle: StrutStyle(
                                                    forceStrutHeight: true,
                                                  ),
                                                  sectionCode,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                iconSize: 30,
                                icon: Icon(Icons.more_vert_rounded),
                                onPressed: () {
                                  _openVersionActions(context, version);
                                },
                              ),
                            ],
                          ),
                          FilledTextButton(
                            text: AppLocalizations.of(context)!.viewPlaceholder(
                              AppLocalizations.of(context)!.cipher,
                            ),
                            isDense: true,
                            isDiscrete: true,
                            onPressed: () {
                              navigationProvider.push(
                                ViewCipherScreen(
                                  versionType: VersionType.playlist,
                                  versionID: widget.versionId,
                                  cipherID: isCloud ? null : version.cipherId,
                                ),
                                showBottomNavBar: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  void _openVersionActions(BuildContext context, final version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return VersionCardActionsSheet(
              itemID: widget.itemId,
              versionID: widget.versionId,
              cipherID: version.cipherId,
              playlistID: widget.playlistId,
            );
          },
        );
      },
    );
  }
}
