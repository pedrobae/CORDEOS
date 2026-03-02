import 'dart:math';

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/library/sheet_actions.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CipherCard extends StatefulWidget {
  final int cipherId;
  final int? playlistId;

  const CipherCard({super.key, required this.cipherId, this.playlistId});

  @override
  State<CipherCard> createState() => _CipherCardState();
}

class _CipherCardState extends State<CipherCard> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer6<
      CipherProvider,
      LocalVersionProvider,
      SectionProvider,
      SelectionProvider,
      PlaylistProvider,
      NavigationProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            versionProvider,
            sectionProvider,
            selectionProvider,
            playlistProvider,
            navigationProvider,
            child,
          ) {
            // Error handling
            if (cipherProvider.error != null || versionProvider.error != null) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.errorMessage(
                    AppLocalizations.of(context)!.loading,
                    cipherProvider.error ?? versionProvider.error!,
                  ),
                ),
              );
            }

            final cipher = cipherProvider.getCipher(widget.cipherId);

            final versionId = versionProvider.getIdOfOldestVersionOfCipher(
              widget.cipherId,
            );

            if (versionId == null) {
              return Container();
            }

            // Loading state
            if (cipherProvider.isLoading || versionProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            final version = versionProvider.cachedVersion(versionId);

            if (version == null || cipher == null) {
              return SizedBox();
            }

            // Card content
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 8.0,
              ), // Spacing between cards
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.surfaceContainerLowest),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            spacing: 2.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TITLE
                              Text(cipher.title, style: textTheme.titleMedium),

                              // INFO
                              Row(
                                spacing: 16.0,
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.musicKey}: ${version.transposedKey ?? cipher.musicKey}',
                                    style: textTheme.bodyMedium,
                                  ),
                                  version.bpm != 0
                                      ? Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.bpmWithPlaceholder(
                                            version.bpm.toString(),
                                          ),
                                          style: textTheme.bodyMedium,
                                        )
                                      : Text('-'),
                                  version.duration != Duration.zero
                                      ? Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.durationWithPlaceholder(
                                            DateTimeUtils.formatDuration(
                                              version.duration,
                                            ),
                                          ),
                                          style: textTheme.bodyMedium,
                                        )
                                      : Text('-'),
                                ],
                              ),

                              // STRUCTURE LIST
                              ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 25),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: version.songStructure.length,
                                  itemBuilder: (_, index) {
                                    final sectionCode =
                                        version.songStructure[index];
                                    final Section section =
                                        version.sections![sectionCode]!;

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

                                    return Container(
                                      height: 25,
                                      width: max(
                                        25,
                                        textPainter.size.width + 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: section.contentColor,
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
                                  },
                                ),
                              ),
                              // SPACER
                              SizedBox(height: 8),
                            ],
                          ),
                        ),

                        // ACTIONS SHEET
                        IconButton(
                          onPressed: () => _openCipherActionsSheet(
                            context,
                            selectionProvider,
                          ),
                          icon: Icon(Icons.more_vert),
                        ),
                      ],
                    ),

                    // VIEW / ADD TO PLAYLIST
                    FilledTextButton(
                      text: (selectionProvider.isSelectionMode)
                          ? AppLocalizations.of(context)!.addToPlaylist
                          : AppLocalizations.of(context)!.viewPlaceholder(''),
                      isDense: true,
                      onPressed: () {
                        if (selectionProvider.isSelectionMode) {
                          selectionProvider.select(versionId);
                          navigationProvider.push(
                            EditCipherScreen(
                              cipherID: widget.cipherId,
                              versionID: versionId,
                              versionType: VersionType.playlist,
                              playlistID: widget.playlistId,
                              isEnabled: false,
                            ),
                            showBottomNavBar: true,
                            changeDetector: () =>
                                (versionProvider.hasUnsavedChanges ||
                                sectionProvider.hasUnsavedChanges ||
                                cipherProvider.hasUnsavedChanges),
                            onPopCallback: () {
                              selectionProvider.deselect(versionId);
                              selectionProvider.enableSelectionMode();
                            },
                          );
                        } else {
                          navigationProvider.push(
                            ViewCipherScreen(
                              cipherID: widget.cipherId,
                              versionID: versionId,
                              versionType: VersionType.local,
                            ),
                            showBottomNavBar: true,
                          );
                        }
                      },
                      onLongPress: () async {
                        if (selectionProvider.isSelectionMode) {
                          selectionProvider.select(versionId);
                        } else {
                          navigationProvider.push(
                            EditCipherScreen(
                              cipherID: widget.cipherId,
                              versionID: versionId,
                              versionType: VersionType.local,
                            ),
                            changeDetector: () =>
                                (versionProvider.hasUnsavedChanges ||
                                sectionProvider.hasUnsavedChanges ||
                                cipherProvider.hasUnsavedChanges),
                            showBottomNavBar: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  void _openCipherActionsSheet(
    BuildContext context,
    SelectionProvider selectionProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return CipherCardActionsSheet(
              cipherId: widget.cipherId,
              versionType: selectionProvider.isSelectionMode
                  ? VersionType.playlist
                  : VersionType.local,
            );
          },
        );
      },
    );
  }
}
