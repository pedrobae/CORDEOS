import 'dart:math';

import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/section_provider.dart';
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

    return Selector2<
      CipherProvider,
      LocalVersionProvider,
      ({Cipher? cipher, Version? version})
    >(
      selector: (context, ciph, localVer) {
        final version = localVer.getVersion(widget.versionID);
        final cipher = version != null
            ? ciph.getCipher(version.cipherID)
            : null;
        return (cipher: cipher, version: version);
      },
      builder: (context, s, child) {
        if (s.version == null || s.cipher == null) {
          return Center(child: CircularProgressIndicator());
        }

        // Card content
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0), // Spacing between cards
          child: GestureDetector(
            onTap: () async {
              if (sel.isSelectionMode) {
                await _createAndAddVersionToPlaylist(s.version!);

                nav.pop();
              } else {
                nav.push(
                  () => ViewCipherScreen(
                    cipherID: s.cipher!.id,
                    versionID: widget.versionID,
                    versionType: VersionType.local,
                  ),
                  showBottomNavBar: true,
                );
              }
            },
            onLongPress: () async {
              final localVer = context.read<LocalVersionProvider>();
              final sect = context.read<SectionProvider>();
              final ciph = context.read<CipherProvider>();

              nav.push(
                () => EditCipherScreen(
                  cipherID: s.cipher!.id,
                  versionID: widget.versionID,
                  versionType: VersionType.local,
                ),
                changeDetector: () {
                  return localVer.hasUnsavedChanges ||
                      sect.hasUnsavedChanges ||
                      ciph.hasUnsavedChanges;
                },
                onChangeDiscarded: () {
                  localVer.loadVersion(widget.versionID);
                  ciph.loadCipher(s.cipher!.id);
                  sect.loadSectionsOfVersion(widget.versionID);
                },
                showBottomNavBar: true,
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
                          Text(s.cipher!.title, style: textTheme.titleMedium),
                
                          // INFO
                          Row(
                            spacing: 16.0,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.musicKey}: ${s.version!.transposedKey ?? s.cipher!.musicKey}',
                                style: textTheme.bodyMedium,
                              ),
                              s.version!.bpm != 0
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.bpmWithPlaceholder(
                                        s.version!.bpm.toString(),
                                      ),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                              s.version!.duration != Duration.zero
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.durationWithPlaceholder(
                                        DateTimeUtils.formatDuration(
                                          s.version!.duration,
                                        ),
                                      ),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                            ],
                          ),
                
                          // STRUCTURE LIST
                          if (!isDense)
                            SizedBox(
                              height: 25,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: s.version!.songStructure.length,
                                itemBuilder: (_, index) {
                                  final sectionCode =
                                      s.version!.songStructure[index];

                                  // Painter for sections code width
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
                
                                  return Selector<SectionProvider, Color>(
                                    selector: (context, sect) {
                                      final section = sect.getSection(
                                        widget.versionID,
                                        sectionCode,
                                      );
                                      return section?.contentColor ??
                                          Colors.grey;
                                    },
                                    builder: (context, color, child) {
                                      return Container(
                                        height: 25,
                                        width: max(25, textPainter.size.width + 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: color,
                                        ),
                                        margin: const EdgeInsets.only(right: 3),
                                        child: Center(
                                          child: Text(
                                            strutStyle: StrutStyle(
                                              forceStrutHeight: true,
                                            ),
                                            sectionCode,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                
                    // ACTIONS SHEET
                    GestureDetector(
                      onTap: _openCipherActionsSheet(s.cipher!.id),
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
          ),
        );
      },
    );
  }

  Future<void> _createAndAddVersionToPlaylist(Version version) async {
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final sect = context.read<SectionProvider>();
    final sel = context.read<SelectionProvider>();

    final playlistName = AppLocalizations.of(
      context,
    )!.playlistVersionName(play.getPlaylist(sel.targetId!)!.name);

    final newVersion = version.copyWith(
      versionName: playlistName,
      firebaseID: '',
    );

    localVer.setNewVersionInCache(newVersion);
    final newVersionID = await localVer.createVersion(
      cipherID: version.cipherID,
    );

    await sect.loadSectionsOfVersion(version.id!);
    sect.cacheCopyOfVersion(version.id!, newVersionID);
    sect.saveSections(versionID: newVersionID);

    sel.addVersionIdToDelete(newVersionID);

    play.cacheAddVersion(sel.targetId!, newVersionID);
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
                cipherId: cipherID,
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
