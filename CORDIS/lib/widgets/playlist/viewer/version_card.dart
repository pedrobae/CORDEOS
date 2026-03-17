import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';

import 'package:cordis/screens/cipher/view_cipher.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/common/custom_reorderable_delayed.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/viewer/version_card_actions.dart';

class PlaylistVersionCard extends StatefulWidget {
  final int playlistId;
  final int versionId;
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
      final localVer = context.read<LocalVersionProvider>();
      final sectionProvider = context.read<SectionProvider>();
      final ciph = context.read<CipherProvider>();

      Version? version = localVer.getVersion(widget.versionId);
      if (version == null) {
        await localVer.loadVersion(widget.versionId);
        version = localVer.getVersion(widget.versionId)!;
      }

      final cipher = ciph.getCipher(version.cipherId);
      if (cipher == null) {
        await ciph.loadCipher(version.cipherId);
      }

      await sectionProvider.loadSectionsOfVersion(widget.versionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nav = context.read<NavigationProvider>();

    return Consumer2<LocalVersionProvider, CipherProvider>(
      builder: (context, localVer, ciph, child) {
        final version = localVer.getVersion(widget.versionId);

        // If version is not loaded yet, show loading indicator
        if (version == null) {
          return Center(child: CircularProgressIndicator());
        }

        final cipher = ciph.getCipher(version.cipherId);

        if (cipher == null) {
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
                                  cipher.title,
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
                                          version.transposedKey ??
                                              cipher.musicKey,
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
                                        version.duration,
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                // REORDERABLE SECTION CHIPS
                                _buildReorderableSectionChips(
                                  version,
                                  songStructure,
                                  localVer,
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
                          nav.push(
                            () => ViewCipherScreen(
                              versionType: VersionType.playlist,
                              versionID: widget.versionId,
                              cipherID: version.cipherId,
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

  Widget _buildReorderableSectionChips(
    Version version,
    List<String> songStructure,
    LocalVersionProvider localVer,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 25),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        proxyDecorator: (child, index, animation) =>
            Material(type: MaterialType.transparency, child: child),
        buildDefaultDragHandles: false,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: songStructure.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          localVer.reorderSongStructure(widget.versionId, oldIndex, newIndex);
        },
        itemBuilder: (_, index) {
          final sectionCode = songStructure[index];
          final color = version.sections![sectionCode]!.contentColor;
          final codeWidth = (TextPainter(
            text: TextSpan(
              text: sectionCode,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          )..layout()).size.width;

          return CustomReorderableDelayed(
            delay: Duration(milliseconds: 100),
            key: ValueKey(
              'ver${widget.versionId}_idx_${widget.index}_sect_${sectionCode}_idx_$index',
            ),
            index: index,
            child: Container(
              height: 25,
              width: max(25, codeWidth + 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                color: color.withValues(alpha: 0.8),
                border: BoxBorder.all(color: color, width: 2),
              ),
              margin: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  strutStyle: StrutStyle(forceStrutHeight: true),
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
    );
  }

  void _openVersionActions(BuildContext context, final version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return VersionCardActionsSheet(
          itemID: widget.itemId,
          versionID: widget.versionId,
          cipherID: version.cipherId,
          playlistID: widget.playlistId,
        );
      },
    );
  }
}
