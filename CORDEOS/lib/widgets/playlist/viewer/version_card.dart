import 'dart:math';

import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/section_badge.dart';
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
  final VersionDto? version;
  final int playlistId;
  final int versionId;
  final int index;
  final int itemId;
  final bool canEdit;

  const PlaylistVersionCard({
    super.key,
    required this.playlistId,
    required this.index,
    required this.versionId,
    required this.itemId,
    required this.canEdit,
    this.version,
  });

  @override
  State<PlaylistVersionCard> createState() => _PlaylistVersionCardState();
}

class _PlaylistVersionCardState extends State<PlaylistVersionCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Pre-load cipher data if not already loaded
    if (widget.version == null) {
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector3<
      LocalVersionProvider,
      CipherProvider,
      SectionProvider,
      ({
        int? cipherID,
        String title,
        String musicKey,
        String duration,
        String bpm,
        Map<int, SectionBadgeData> badgesData,
        List<int> songStructure,
      })
    >(
      selector: (context, localVer, ciph, sect) {
        if (widget.version != null) {
          final sectionTypes = <int, SectionType>{};
          for (var key in widget.version!.songStructure) {
            final type = widget.version!.sections[key]?.sectionType;
            if (type != null) {
              sectionTypes[key] = type;
            } else {
              sectionTypes[key] = SectionType.unknown;
            }
          }
          return (
            cipherID: -1,
            title: widget.version!.title,
            musicKey:
                widget.version!.transposedKey ?? widget.version!.originalKey,
            duration: DateTimeUtils.formatDuration(
              Duration(seconds: widget.version!.duration),
            ),
            bpm: widget.version!.bpm.toString(),
            badgesData: getSectionBadges(sectionTypes),
            songStructure: widget.version!.songStructure,
          );
        }
        final version = localVer.getVersion(widget.versionId);
        final cipher = version != null
            ? ciph.getCipher(version.cipherID)
            : null;

        final songStructure = version?.songStructure;

        final sectionTypes = <int, SectionType>{};
        for (var key in songStructure ?? []) {
          final type = sect
              .getSection(versionKey: widget.versionId, sectionKey: key)
              ?.sectionType;
          if (type != null) {
            sectionTypes[key] = type;
          } else {
            sectionTypes[key] = SectionType.unknown;
          }
        }
        return (
          cipherID: cipher?.id,
          title: cipher?.title ?? '',
          musicKey: version?.transposedKey ?? cipher?.musicKey ?? '',
          duration: (version != null && version.duration != Duration.zero)
              ? DateTimeUtils.formatDuration(version.duration)
              : '-',
          bpm: (version != null && version.bpm != 0)
              ? version.bpm.toString()
              : '-',
          badgesData: getSectionBadges(sectionTypes),
          songStructure: songStructure ?? [],
        );
      },
      builder: (context, s, child) {
        if (s.cipherID == null) {
          return Center(child: CircularProgressIndicator());
        }

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
              if (widget.canEdit)
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
                        versionDto: widget.version,
                        cipherID: s.cipherID,
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
                          s.title,
                          style: textTheme.titleMedium,
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
                                  style: textTheme.bodyMedium,
                                ),
                                Text(s.musicKey, style: textTheme.bodyMedium),
                              ],
                            ),
                            Text(
                              '${AppLocalizations.of(context)!.bpm}: ${s.bpm}',
                              style: textTheme.bodyMedium,
                            ),
                            Text(s.duration, style: textTheme.bodyMedium),
                          ],
                        ),
                        // REORDERABLE SECTION CHIPS
                        widget.canEdit
                            ? _buildReorderableSectionChips(
                                s.badgesData,
                                s.songStructure,
                              )
                            : SizedBox(
                                height: 25,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: s.songStructure.length,
                                  itemBuilder: (_, index) {
                                    final key = s.songStructure[index];
                                    final badgeData = s.badgesData[key];
                                    if (badgeData == null) {
                                      return SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 2.0,
                                      ),
                                      child: SectionBadge(
                                        sectionBadgeData: badgeData,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.canEdit)
                GestureDetector(
                  onTap: () {
                    _openVersionActions(context, s.cipherID!);
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
    Map<int, SectionBadgeData> badgesData,
    List<int> songStructure,
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
        itemCount: badgesData.length,
        onReorder: (oldIndex, newIndex) {
          localVer.reorderSongStructure(widget.versionId, oldIndex, newIndex);
        },
        itemBuilder: (_, index) {
          final key = songStructure[index];
          final badgeData = badgesData[key]!;
          final codeWidth = (TextPainter(
            text: TextSpan(
              text: badgeData.code,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          )..layout()).size.width;

          return CustomReorderableDelayed(
            key: ValueKey(
              'ver${widget.versionId}_idx_${widget.index}_sect_${badgesData.hashCode}_idx_$index',
            ),
            delay: Duration(milliseconds: 100),
            index: index,
            child: Container(
              height: 25,
              width: max(25, codeWidth + 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                color: badgeData.color.withValues(alpha: 0.8),
                border: Border.all(color: badgeData.color, width: 2),
              ),
              margin: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  strutStyle: StrutStyle(forceStrutHeight: true),
                  badgeData.code,
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

  void _openVersionActions(BuildContext context, int cipherID) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return VersionCardActionsSheet(
          itemID: widget.itemId,
          versionID: widget.versionId,
          cipherID: cipherID,
          playlistID: widget.playlistId,
        );
      },
    );
  }
}
