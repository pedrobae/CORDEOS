import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/library/sheet_links.dart';
import 'package:cordeos/widgets/ciphers/section_badge.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/selection_provider.dart';
import 'package:cordeos/providers/settings/secret_settings_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

import 'package:cordeos/screens/cipher/edit_cipher.dart';
import 'package:cordeos/screens/cipher/view_cipher.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/ciphers/library/sheet_actions.dart';

class CipherCard extends StatefulWidget {
  final int versionID;

  const CipherCard({super.key, required this.versionID});

  @override
  State<CipherCard> createState() => _CipherCardState();
}

class _CipherCardState extends State<CipherCard> {
  late bool isDense;

  @override
  void initState() {
    super.initState();
    final secSet = context.read<SecretSetProvider>();
    final sect = context.read<SectionProvider>();

    isDense = secSet.denseCipherCard;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await sect.loadSectionsOfVersion(widget.versionID);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final sel = context.read<SelectionProvider>();

    if (widget.versionID == -1) {
      return SizedBox.shrink();
    }

    return Selector3<
      CipherProvider,
      LocalVersionProvider,
      SectionProvider,
      ({
        int? cipherID,
        String? title,
        String? key,
        String? duration,
        String? bpm,
        List<String>? links,
        Map<int, SectionBadgeData> sectionBadges,
        List<int> songStructure,
      })
    >(
      selector: (context, ciph, localVer, sect) {
        final version = localVer.getVersion(widget.versionID);
        final cipher = version != null
            ? ciph.getCipher(version.cipherID)
            : null;

        final sectionTypes = <int, SectionType>{};
        for (var sectionKey in version?.songStructure.toSet().toList() ?? []) {
          final section = sect.getSection(
            versionKey: widget.versionID,
            sectionKey: sectionKey,
          );

          if (section?.sectionType != null) {
            sectionTypes[sectionKey] = section!.sectionType;
          }
        }

        return (
          cipherID: cipher?.id,
          title: cipher?.title ?? '',
          key: version?.transposedKey ?? cipher?.musicKey ?? '',
          duration: version != null && version.duration != Duration.zero
              ? DateTimeUtils.formatDuration(version.duration)
              : null,
          bpm: version != null && version.bpm != 0
              ? version.bpm.toString()
              : null,
          links: cipher?.links,
          sectionBadges: getSectionBadges(sectionTypes),
          songStructure: version?.songStructure ?? [],
        );
      },
      builder: (context, s, child) {
        if (s.cipherID == null) {
          return SizedBox.shrink();
        }

        // Card content
        return GestureDetector(
          onTap: () async {
            if (sel.isSelectionMode) {
              await _createAndAddVersionToPlaylist();

              nav.pop();
            } else {
              final token = context.read<TokenProvider>();
              nav.push(
                () => ViewCipherScreen(
                  cipherID: s.cipherID!,
                  versionID: widget.versionID,
                  versionType: VersionType.local,
                ),
                onPopCallback: () {
                  token.clear();
                },
                showBottomNavBar: true,
              );
            }
          },
          onLongPress: () async {
            final localVer = context.read<LocalVersionProvider>();
            final ciph = context.read<CipherProvider>();
            final sect = context.read<SectionProvider>();
            nav.push(
              () => EditCipherScreen(
                cipherID: s.cipherID!,
                versionID: widget.versionID,
                versionType: VersionType.local,
              ),
              keepAlive: true,
              changeDetector: () {
                return localVer.hasUnsavedChanges ||
                    ciph.hasUnsavedChanges ||
                    sect.hasUnsavedChanges;
              },
              onChangeDiscarded: () {
                localVer.loadVersion(widget.versionID);
                ciph.loadCipher(s.cipherID!);
                sect.loadSectionsOfVersion(widget.versionID);
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.surfaceContainerLowest),
            ),
            padding: const EdgeInsets.all(8.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      spacing: 2.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE
                        Text(s.title!, style: textTheme.titleMedium),

                        // INFO
                        Row(
                          spacing: 16.0,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.musicKey}: ${s.key}',
                              style: textTheme.bodyMedium,
                            ),
                            if (s.bpm != null)
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.bpmWithPlaceholder(s.bpm!),
                                style: textTheme.bodyMedium,
                              ),
                            if (s.duration != null && s.duration!.isNotEmpty)
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.durationWithPlaceholder(s.duration!),
                                style: textTheme.bodyMedium,
                              ),
                          ],
                        ),

                        // STRUCTURE LIST
                        if (!isDense)
                          SizedBox(
                            height: 25,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: s.songStructure.length,
                              itemBuilder: (_, index) {
                                final key = s.songStructure[index];
                                final badgeData = s.sectionBadges[key];
                                if (badgeData == null) {
                                  return SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2.0),
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

                  if (s.links!.any((link) {
                    return link.isNotEmpty;
                  }))
                    GestureDetector(
                      onTap: _openLinksSheet(s.links!),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.link, size: 20),
                      ),
                    ),

                  // ACTIONS SHEET
                  GestureDetector(
                    onTap: _openCipherActionsSheet(s.cipherID!),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: double.infinity,
                      width: 40,
                      child: Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createAndAddVersionToPlaylist() async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final sel = context.read<SelectionProvider>();

    final playVersionName = AppLocalizations.of(
      context,
    )!.playlistVersionName(play.getPlaylist(sel.targetId!)!.name);

    final version = localVer.getVersion(widget.versionID)!;

    final newVersion = version.copyWith(
      versionName: playVersionName,
      firebaseID: '',
    );

    localVer.setNewVersionInCache(newVersion);
    final newVersionID = await localVer.createVersion(
      cipherID: version.cipherID,
    );

    await sect.loadSectionsOfVersion(version.id!);
    sect.cacheCopyOfVersion(version.id!, newVersionID);
    await sect.saveSections(versionID: newVersionID);

    sel.addVersionIdToDelete(newVersionID);

    play.cacheAddVersion(sel.targetId!, newVersionID);
  }

  VoidCallback _openLinksSheet(List<String> links) {
    return () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return BottomSheet(
            shape: LinearBorder(),
            onClosing: () {},
            builder: (context) {
              return LinksSheet(links: links);
            },
          );
        },
      );
    };
  }

  VoidCallback _openCipherActionsSheet(int cipherID) {
    return () {
      final sel = context.read<SelectionProvider>();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return BottomSheet(
            shape: LinearBorder(),
            onClosing: () {},
            builder: (context) {
              return CipherCardActionsSheet(
                cipherID: cipherID,
                versionType: sel.isSelectionMode
                    ? VersionType.playlist
                    : VersionType.local,
              );
            },
          );
        },
      );
    };
  }
}
