import 'dart:math';

import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';

import 'package:cordeos/screens/cipher/view_cipher.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/common/custom_reorderable_delayed.dart';
import 'package:cordeos/widgets/playlist/viewer/version_card_actions.dart';

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
      await localVer.loadVersion(widget.versionId);
      version = localVer.getVersion(widget.versionId);

      if (version == null) {
        throw Exception('Failed to load version with ID ${widget.versionId}');
      }

      final cipher = ciph.getCipher(version.cipherID);
      if (cipher == null) {
        await ciph.loadCipher(version.cipherID);
      }

      await sectionProvider.loadSectionsOfVersion(widget.versionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector2<
      LocalVersionProvider,
      CipherProvider,
      ({Version? version, Cipher? cipher})
    >(
      selector: (context, localVer, ciph) {
        final version = localVer.getVersion(widget.versionId);
        final cipher = version != null
            ? ciph.getCipher(version.cipherID)
            : null;
        return (version: version, cipher: cipher);
      },
      builder: (context, s, child) {
        if (s.version == null || s.cipher == null) {
          return Center(child: CircularProgressIndicator());
        }

        final List<String> songStructure = s.version!.songStructure;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(0),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              CustomReorderableDelayed(
                delay: Duration(milliseconds: 100),
                index: widget.index,
                child: Container(
                  // Container to paint and enable hitbox for the icon
                  color: Colors.transparent,
                  height: 93,
                  child: Icon(Icons.drag_indicator, size: 30),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final token = context.read<TokenProvider>();
                    nav.push(
                      () => ViewCipherScreen(
                        versionType: VersionType.playlist,
                        versionID: widget.versionId,
                        cipherID: s.version!.cipherID,
                      ),
                      onPopCallback: () {
                        token.clear();
                      },
                      showBottomNavBar: true,
                    );
                  },
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
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.cipher!.title,
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
                                  s.version!.transposedKey ??
                                      s.cipher!.musicKey,
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
                                  s.version!.bpm.toString(),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Text(
                              DateTimeUtils.formatDuration(s.version!.duration),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        // REORDERABLE SECTION CHIPS
                        _buildReorderableSectionChips(
                          s.version!,
                          songStructure,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _openVersionActions(context, s.version!);
                },
                child: Container(
                  // Container to paint and enable hitbox for the icon
                  color: Colors.transparent,
                  height: 93,
                  child: Icon(Icons.more_vert_rounded, size: 30),
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
  ) {
    final localVer = context.read<LocalVersionProvider>();

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

          return Selector<SectionProvider, Color>(
            key: ValueKey(
              'ver${widget.versionId}_idx_${widget.index}_sect_${sectionCode}_idx_$index',
            ),
            selector: (context, sect) {
              final sectionCode = songStructure[index];
              return sect
                      .getSections(widget.versionId)[sectionCode]
                      ?.contentColor ??
                  Colors.grey;
            },
            builder: (context, color, child) {
              final codeWidth = (TextPainter(
                text: TextSpan(
                  text: sectionCode,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                textDirection: TextDirection.ltr,
              )..layout()).size.width;

              return CustomReorderableDelayed(
                delay: Duration(milliseconds: 100),
                index: index,
                child: Container(
                  height: 25,
                  width: max(25, codeWidth + 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    color: color.withValues(alpha: 0.8),
                    border: Border.all(color: color, width: 2),
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
          );
        },
      ),
    );
  }

  void _openVersionActions(BuildContext context, Version version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return VersionCardActionsSheet(
          itemID: widget.itemId,
          versionID: widget.versionId,
          cipherID: version.cipherID,
          playlistID: widget.playlistId,
        );
      },
    );
  }
}
