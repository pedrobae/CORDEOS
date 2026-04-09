import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/providers/cipher/edit_sections_state_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/chord_palette.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/merge_structure.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/sheet_new_section.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/sheet_manage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/reorderable_structure.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/token_content_card.dart';

class SectionsTab extends StatefulWidget {
  final int versionID;
  final VersionType versionType;
  final bool isEnabled;

  const SectionsTab({
    super.key,
    required this.versionID,
    required this.versionType,
    this.isEnabled = true,
  });

  @override
  State<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends State<SectionsTab> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Selector<LocalVersionProvider, List<String>>(
      selector: (context, localVer) {
        return localVer.getSongStructure(widget.versionID);
      },
      builder: (context, songStructure, child) {
        final uniqueSections = songStructure.toSet().toList();

        return Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 32,
                  children: [
                    // STRUCTURE SECTION
                    Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // LABEL
                            Text(
                              AppLocalizations.of(context)!.songStructure,
                              style: textTheme.titleMedium,
                            ),

                            if (uniqueSections.isNotEmpty)
                              // MANAGE SECTION BUTTON
                              GestureDetector(
                                onTap: _openRepeatSectionSheet(),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.managePlaceholder(''),
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // DRAGGABLE CHIPS
                        ReorderableStructure(
                          versionID: widget.versionID,
                          showDelete: false,
                        ),
                      ],
                    ),
                    // CONTENT SECTION
                    Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LABEL
                        Text(
                          AppLocalizations.of(context)!.lyrics,
                          style: textTheme.titleMedium,
                        ),

                        // SECTIONS
                        if (uniqueSections.isEmpty)
                          Text(
                            AppLocalizations.of(context)!.noLyrics,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          )
                        else
                          ...uniqueSections.map((sectionCode) {
                            return TokenContentCard(
                              versionID: widget.versionID,
                              sectionCode: sectionCode,
                              isEnabled: widget.isEnabled,
                            );
                          }),
                      ],
                    ),
                    SizedBox(height: 200), // Extra space for FAB
                  ],
                ),
              ),
            ),
            if (widget.isEnabled)
              Selector<
                EditSectionsStateProvider,
                ({bool paletteIsOpen, bool mergeOverlayIsOpen})
              >(
                selector: (context, state) => (
                  paletteIsOpen: state.paletteIsOpen,
                  mergeOverlayIsOpen: state.mergeOverlayIsOpen,
                ),
                builder: (context, s, child) {
                  return Positioned(
                    bottom: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      verticalDirection: VerticalDirection.up,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.paletteIsOpen)
                          ChordPalette(versionID: widget.versionID),

                        if (s.mergeOverlayIsOpen)
                          MergeStructure(versionID: widget.versionID),

                        // Palette FAB
                        if (widget.isEnabled)
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<EditSectionsStateProvider>()
                                  .togglePalette();
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.surfaceContainerLowest,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                s.paletteIsOpen
                                    ? Icons.close
                                    : Icons.music_note,
                                size: 28,
                                color: colorScheme.surface,
                              ),
                            ),
                          ),

                        // Open add sheet
                        GestureDetector(
                          onTap: _openAddSheet(),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.surfaceContainerLowest,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              size: 28,
                              color: colorScheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  VoidCallback _openAddSheet() {
    return () {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return NewSectionSheet(versionID: widget.versionID);
        },
      );
    };
  }

  VoidCallback _openRepeatSectionSheet() {
    return () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        builder: (context) {
          return ManageSheet(versionID: widget.versionID);
        },
      );
    };
  }
}
