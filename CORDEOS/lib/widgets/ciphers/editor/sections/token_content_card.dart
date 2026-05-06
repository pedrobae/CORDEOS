import 'package:cordeos/utils/section_type.dart';
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
  final int sectionKey;
  final SectionBadgeData sectionBadgeData;
  final bool isEnabled;

  const TokenContentCard({
    super.key,
    required this.versionID,
    required this.sectionKey,
    required this.sectionBadgeData,
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

  Function(ContentToken, ContentToken, {bool addBefore, bool isChordTarget})
  _addChord(TokenCacheKey key) {
    return (
      draggedChord,
      targetToken, {
      bool addBefore = true,
      bool isChordTarget = false,
    }) {
      final sect = context.read<SectionProvider>();
      final tokenProv = context.read<TokenProvider>();

      final tokens = tokenProv.getTokens(key);

      if (tokens == null) return;

      int index = tokens.indexWhere((t) => t == targetToken);
      if (index == -1) return;
      if (!addBefore) index++;
      if (isChordTarget) index++;
      tokens.insert(index, draggedChord);

      final updatedContent = tokenProv.getContent(key);

      sect.cacheUpdate(
        widget.versionID,
        widget.sectionKey,
        newContentText: updatedContent,
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

      sect.cacheUpdate(
        widget.versionID,
        widget.sectionKey,
        newContentText: updatedContent,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    _tokensKey = TokenCacheKey(sectionKey: widget.sectionKey, isEditMode: true);

    return Selector<SectionProvider, ({Section? section, String? contentText})>(
      selector: (context, sect) {
        final section = sect.getSection(
          versionKey: widget.versionID,
          sectionKey: widget.sectionKey,
        );
        return (section: section, contentText: section?.contentText);
      },
      builder: (context, s, child) {
        _tokenProv.clearSectionKey(_tokensKey!);
        if (s.section == null) {
          return const Center(child: CircularProgressIndicator());
        }

        _tokensKey!.content = s.contentText;

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
                    SectionBadge(sectionBadgeData: widget.sectionBadgeData),

                    /// Section Type label
                    Text(s.section!.contentType, style: textTheme.bodyLarge),

                    /// Delete icon (only visible when dragging)
                    Expanded(
                      child:
                          Selector<
                            TokenProvider,
                            ({
                              bool isDragging,
                              Function(ContentToken) removeChord,
                            })
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
                                          (
                                            context,
                                            candidateData,
                                            rejectedData,
                                          ) {
                                            if (candidateData.isNotEmpty) {
                                              return Align(
                                                alignment: AlignmentGeometry
                                                    .centerRight,
                                                child: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 28,
                                                ),
                                              );
                                            }
                                            return Align(
                                              alignment:
                                                  AlignmentGeometry.centerRight,

                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.grey,
                                                size: 28,
                                              ),
                                            );
                                          },
                                    )
                                  : SizedBox(width: 28);
                            },
                          ),
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
              Selector<TranspositionProvider, int>(
                selector: (context, trans) => trans.transposeValue,
                builder: (context, transposeValue, child) {
                  // PHASE 1: Ensure tokens are cached & organized for this content + filters
                  _tokensKey!.transposeValue = transposeValue;

                  _tokenProv.tokenize(
                    _tokensKey!,
                    transposeChord: (chord) => chord,
                  );
                  _tokenProv.organize(_tokensKey!);
                  return Selector2<
                    LayoutSetProvider,
                    TranspositionProvider,
                    ({
                      TextStyle lyricStyle,
                      TextStyle chordStyle,
                      double heightSpacing,
                    })
                  >(
                    selector: (context, laySet, trans) => (
                      lyricStyle: laySet.lyricStyle,
                      chordStyle: laySet.chordStyle,
                      heightSpacing: laySet.heightSpacing,
                    ),
                    builder: (context, measure, child) {
                      // PHASE 2: Ensure measurements are cached for this content + style
                      _tokensKey!.heightSpacing = measure.heightSpacing;
                      _tokenProv.measureTokens(
                        chordStyle: measure.chordStyle,
                        lyricStyle: measure.lyricStyle,
                        key: _tokensKey!,
                      );

                      return Selector<
                        LayoutSetProvider,
                        ({
                          double heightSpacing,
                          double minChordSpacing,
                          double letterSpacing,
                        })
                      >(
                        selector: (context, laySet) {
                          return (
                            letterSpacing: laySet.letterSpacing,
                            heightSpacing: laySet.heightSpacing,
                            minChordSpacing: laySet.minChordSpacing,
                          );
                        },
                        builder: (context, l, child) {
                          // PHASE 3: Calculate and cache widget positions based on width constraints
                          final width =
                              MediaQuery.sizeOf(context).width -
                              2.4 - // Container border
                              8 - // Container padding
                              32 - // ScrollView padding
                              TokenizationConstants.chordTokenWidthPadding;
                          _tokensKey!.heightSpacing = l.heightSpacing;
                          _tokensKey!.minChordSpacing = l.minChordSpacing;
                          _tokensKey!.letterSpacing = l.letterSpacing;
                          _tokensKey!.maxWidth = width;

                          _tokenProv.calculatePositions(
                            key: _tokensKey!,
                            lyricStyle: measure.lyricStyle,
                            chordStyle: measure.chordStyle,
                          );

                          final positions = _tokenProv.getPositions(
                            _tokensKey!,
                            measure.chordStyle,
                            measure.lyricStyle,
                          );

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

                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              padding: const EdgeInsets.only(
                                left: TokenizationConstants
                                    .chordTokenWidthPadding,
                              ),
                              width: width,
                              height: positions?.contentHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [...content.tokens],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
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
                  final nav = context.read<NavigationProvider>();
                  final sect = context.read<SectionProvider>();

                  Navigator.pop(context); // Close the bottom sheet
                  nav.push(
                    () => EditSectionScreen(
                      versionID: widget.versionID,
                      sectionKey: widget.sectionKey,
                    ),
                    showBottomNavBar: true,
                    onChangeDiscarded: () =>
                        sect.loadSection(widget.versionID, widget.sectionKey),
                    changeDetector: () {
                      return sect.hasUnsavedChanges;
                    },
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
                  state.toggleMergeSection(widget.sectionKey);
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
                  final newKey = sect.cacheCopyOfSection(
                    versionId: widget.versionID,
                    sectionKey: widget.sectionKey,
                  );
                  if (newKey != null) {
                    context.read<LocalVersionProvider>().addSectionToStruct(
                      widget.versionID,
                      newKey,
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
                    widget.sectionKey,
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
                            widget.sectionKey,
                          );
                          context
                              .read<LocalVersionProvider>()
                              .removeSectionsByKey(
                                widget.versionID,
                                widget.sectionKey,
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
