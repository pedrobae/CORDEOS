import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/section.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/edit_sections_state_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

import 'package:cordeos/services/tokenization/helper_classes.dart';

import 'package:cordeos/utils/token_cache_keys.dart';

import 'package:cordeos/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:cordeos/widgets/ciphers/section_badge.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class TokenContentCard extends StatefulWidget {
  final int versionID;
  final String sectionCode;
  final bool isEnabled;

  const TokenContentCard({
    super.key,
    required this.versionID,
    required this.sectionCode,
    this.isEnabled = true,
  });

  @override
  State<TokenContentCard> createState() => _TokenContentCardState();
}

class _TokenContentCardState extends State<TokenContentCard> {
  late TokenProvider _tokenProv;
  TokenCacheKey? _tokensKey;

  @override
  void initState() {
    super.initState();
    _tokenProv = context.read<TokenProvider>();
  }

  Function(ContentToken, ContentToken) _addChord(TokenCacheKey key) {
    return (draggedChord, targetToken) {
      final sect = context.read<SectionProvider>();
      final tokenProv = context.read<TokenProvider>();

      final tokens = tokenProv.getTokens(key);

      if (tokens == null) return;

      final index = tokens.indexWhere((t) => t == targetToken);
      if (index == -1) return;
      tokens.insert(index, draggedChord);

      final updatedContent = tokenProv.getContent(key);

      sect.cacheContent(
        versionID: widget.versionID,
        sectionCode: widget.sectionCode,
        content: updatedContent,
      );
    };
  }

  Function(ContentToken) _removeChord(TokenCacheKey key) {
    return (contentToken) {
      final sect = context.read<SectionProvider>();
      final tokenProv = context.read<TokenProvider>();

      final tokens = tokenProv.getTokens(key);

      if (tokens == null) return;

      final index = tokens.indexWhere((t) => t == contentToken);
      if (index == -1) return;

      tokens.removeAt(index);

      final updatedContent = tokenProv.getContent(key);

      sect.cacheContent(
        versionID: widget.versionID,
        sectionCode: widget.sectionCode,
        content: updatedContent,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;

    return Selector<SectionProvider, ({Section? section, String? contentText})>(
      selector: (context, sect) {
        final section = sect.getSection(widget.versionID, widget.sectionCode);
        return (section: section, contentText: section?.contentText);
      },
      builder: (context, s, child) {
        if (s.section == null) {
          return const Center(child: CircularProgressIndicator());
        }

        _tokensKey = TokenCacheKey(content: s.contentText ?? '', isEditMode: true);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: colorScheme.shadow, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  border: Border(
                    bottom: BorderSide(color: colorScheme.shadow, width: 1.2),
                  ),
                ),
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    /// Section Code badge
                    SectionBadge(
                      sectionCode: s.section!.contentCode,
                      sectionColor: s.section!.contentColor,
                    ),

                    /// Section Type label
                    Expanded(
                      child: Text(
                        s.section!.contentType,
                        style: textTheme.bodyLarge,
                      ),
                    ),

                    /// Delete icon (only visible when dragging)
                    Selector<
                      TokenProvider,
                      ({bool isDragging, Function(ContentToken) removeChord})
                    >(
                      selector: (context, tokenProv) => (
                        isDragging: tokenProv.isDragging,
                        removeChord: _removeChord(_tokensKey!),
                      ),
                      builder: (context, s, child) {
                        return s.isDragging
                            ? DragTarget<ContentToken>(
                                onAcceptWithDetails: (details) => {
                                  s.removeChord(details.data),
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                      if (candidateData.isNotEmpty) {
                                        return Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        );
                                      }
                                      return Icon(
                                        Icons.delete,
                                        color: Colors.grey,
                                      );
                                    },
                              )
                            : SizedBox(width: 28);
                      },
                    ),

                    /// Edit Section button
                    if (widget.isEnabled)
                      GestureDetector(
                        onTap: _showQuickActions,
                        child: Icon(
                          Icons.more_vert,
                          size: 28,
                          color: colorScheme.shadow,
                        ),
                      ),
                  ],
                ),
              ),

              /// CONTENT
              Padding(
                padding: const EdgeInsets.all(4),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: TokenizationConstants.chordTokenWidthPadding,
                  ),
                  child:
                      Selector2<
                        LayoutSetProvider,
                        TranspositionProvider,
                        ({
                          bool showLyrics,
                          bool showChords,
                          int transposeValue,
                        })
                      >(
                        selector: (context, laySet, trans) => (
                          showLyrics: laySet.showLyrics,
                          showChords: laySet.showChords,
                          transposeValue: trans.transposeValue,
                        ),
                        builder: (context, filter, child) {
                          final trans = context.read<TranspositionProvider>();
                          // PHASE 1: Ensure tokens are cached & organized for this content + filters
                          _tokensKey!.showChords = filter.showChords;
                          _tokensKey!.showLyrics = filter.showLyrics;
                          _tokensKey!.transposeValue = filter.transposeValue;

                          _tokenProv.tokenize(
                            _tokensKey!,
                            transposeChord: trans.transposeChord,
                          );
                          _tokenProv.organize(_tokensKey!);
                          return Selector2<
                            LayoutSetProvider,
                            TranspositionProvider,
                            ({
                              TextStyle lyricStyle,
                              TextStyle chordStyle,
                              double chordLyricSpacing,
                            })
                          >(
                            selector: (context, laySet, trans) => (
                              lyricStyle: laySet.lyricStyle,
                              chordStyle: laySet.chordStyle,
                              chordLyricSpacing: laySet.chordLyricSpacing,
                            ),
                            builder: (context, measure, child) {
                              // PHASE 2: Ensure measurements are cached for this content + style
                              _tokensKey!.chordLyricSpacing =
                                  measure.chordLyricSpacing;
                              _tokenProv.measureTokens(
                                chordStyle: measure.chordStyle,
                                lyricStyle: measure.lyricStyle,
                                key: _tokensKey!,
                              );

                              return Selector<
                                LayoutSetProvider,
                                ({
                                  double maxWidth,
                                  double letterSpacing,
                                  double lineSpacing,
                                  double lineBreakSpacing,
                                  double minChordSpacing,
                                })
                              >(
                                selector: (context, laySet) {
                                  return (
                                    maxWidth:
                                        screenWidth * laySet.cardWidthMult,
                                    letterSpacing: laySet.letterSpacing,
                                    lineSpacing: laySet.lineSpacing,
                                    lineBreakSpacing: laySet.lineBreakSpacing,
                                    minChordSpacing: laySet.minChordSpacing,
                                  );
                                },
                                builder: (context, l, child) {
                                  // PHASE 3: Calculate and cache widget positions based on width constraints
                                  _tokensKey!.maxWidth = l.maxWidth;
                                  _tokensKey!.letterSpacing = l.letterSpacing;
                                  _tokensKey!.lineSpacing = l.lineSpacing;
                                  _tokensKey!.lineBreakSpacing =
                                      l.lineBreakSpacing;
                                  _tokensKey!.minChordSpacing =
                                      l.minChordSpacing;

                                  _tokenProv.calculatePositions(
                                    key: _tokensKey!,
                                    lyricStyle: measure.lyricStyle,
                                    chordStyle: measure.chordStyle,
                                  );

                                  final positions = _tokenProv.getPositions(_tokensKey!);

                                  final content = _tokenProv.buildEditWidgets(
                                    key: _tokensKey!,
                                    lyricStyle: measure.lyricStyle,
                                    chordStyle: measure.chordStyle,
                                    contentColor: s.section!.contentColor,
                                    chordTargetColor: colorScheme.surfaceTint,
                                    surfaceColor: colorScheme.surface,
                                    onSurfaceColor: colorScheme.onSurface,
                                    onContentColor: colorScheme.surface,
                                    isEnabled: widget.isEnabled,
                                    onAddChord: _addChord(_tokensKey!),
                                    onRemoveChord: _removeChord(_tokensKey!),
                                  );

                                  return SizedBox(
                                    width: double.infinity,
                                    height: positions?.contentHeight,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [...content.tokens],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.quickAction,
                    style: textTheme.titleMedium,
                  ),
                  CloseButton(onPressed: () => Navigator.pop(context)),
                ],
              ),

              // ACTIONS
              // edit
              FilledTextButton(
                text: AppLocalizations.of(context)!.editPlaceholder(''),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  context.read<NavigationProvider>().pushForeground(
                    EditSectionScreen(
                      versionID: widget.versionID,
                      sectionCode: widget.sectionCode,
                    ),
                  );
                },
              ),
              // merge
              FilledTextButton(
                text: AppLocalizations.of(context)!.mergePlaceholder(''),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  final state = context.read<EditSectionsStateProvider>();
                  state.enableMergeOverlay();
                  state.toggleMergeSection(widget.sectionCode);
                },
              ),
              // create copy
              FilledTextButton(
                text: AppLocalizations.of(
                  context,
                )!.createPlaceholder(AppLocalizations.of(context)!.copy),
                trailingIcon: Icons.chevron_right,
                tooltip: AppLocalizations.of(context)!.copySectionTooltip,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  final sect = context.read<SectionProvider>();
                  final newCode = sect.cacheCopyOfSection(
                    versionId: widget.versionID,
                    sectionCode: widget.sectionCode,
                  );
                  if (newCode != null) {
                    context.read<LocalVersionProvider>().addSectionToStruct(
                      widget.versionID,
                      newCode,
                    );
                  }
                },
              ),
              // duplicate (just to map)
              FilledTextButton(
                text: AppLocalizations.of(
                  context,
                )!.duplicatePlaceholder(AppLocalizations.of(context)!.section),
                trailingIcon: Icons.chevron_right,
                tooltip: AppLocalizations.of(context)!.duplicateSectionTooltip,
                isDiscrete: true,
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  context.read<LocalVersionProvider>().addSectionToStruct(
                    widget.versionID,
                    widget.sectionCode,
                  );
                },
              ),
              // delete
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                isDangerous: true,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.section,
                        onConfirm: () {
                          context.read<SectionProvider>().cacheDeletion(
                            widget.versionID,
                            widget.sectionCode,
                          );
                          context
                              .read<LocalVersionProvider>()
                              .removeSectionsByCode(
                                widget.versionID,
                                widget.sectionCode,
                              );
                          Navigator.pop(context); // Close quick actions sheet
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
