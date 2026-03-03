import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:cordis/widgets/ciphers/section_badge.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordis/models/ui/content_token.dart';
import 'package:cordis/services/tokenization_service.dart';
import 'package:provider/provider.dart';

class TokenContentCard extends StatefulWidget {
  final dynamic versionID;
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
  final TokenizationService _tokenizer = TokenizationService();

  bool _isDragging = false;

  bool _isEnabled(SelectionProvider selectionProvider) {
    if (!widget.isEnabled) return false;
    return !selectionProvider.isSelectionMode;
  }

  void _toggleDrag() {
    setState(() {
      _isDragging = !_isDragging;
    });
  }

  void _cacheChanges(List<ContentToken> tokens) {
    final newContent = _tokenizer.reconstructContent(
      tokens, // Excludes the last newline token
    );

    context.read<SectionProvider>().cacheUpdate(
      widget.versionID,
      widget.sectionCode,
      newContentText: newContent,
    );
  }

  void _addChord(List<ContentToken> tokens, ContentToken token, int position) {
    tokens.insert(position, token);

    _cacheChanges(tokens);
  }

  void _addPrecedingChord(
    List<ContentToken> tokens,
    ContentToken token,
    int position,
  ) {
    final emptySpaceToken = ContentToken(text: ' ', type: TokenType.space);
    final newToken = ContentToken(text: token.text, type: token.type);

    tokens.insert(position, emptySpaceToken);
    tokens.insert(position, newToken);

    _cacheChanges(tokens);
  }

  void _removeChordAt(List<ContentToken> tokens, int position) {
    tokens.removeAt(position);

    _cacheChanges(tokens);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer4<
      LayoutSettingsProvider,
      SectionProvider,
      SelectionProvider,
      TranspositionProvider
    >(
      builder:
          (
            context,
            layoutSettingsProvider,
            sectionProvider,
            selectionProvider,
            tp,
            child,
          ) {
            final section = sectionProvider.getSection(
              widget.versionID,
              widget.sectionCode,
            );

            // Handle case where section doesn't exist
            if (section == null || section.contentText.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: colorScheme.shadow, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Section not found or empty',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            }

            final tokens = _tokenizer.tokenize(section.contentText);
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.shadow,
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        /// Drag Handle icon
                        Icon(
                          Icons.drag_indicator,
                          size: 28,
                          color: colorScheme.shadow,
                        ),

                        /// Section Code badge
                        SectionBadge(
                          sectionCode: section.contentCode,
                          sectionColor: section.contentColor,
                        ),

                        /// Section Type label
                        Expanded(
                          child: Text(
                            section.contentType,
                            style: textTheme.bodyLarge,
                          ),
                        ),

                        /// Delete icon (only visible when dragging)
                        _isDragging
                            ? DragTarget<ContentToken>(
                                onAcceptWithDetails: (details) => {
                                  _removeChordAt(
                                    tokens,
                                    details.data.position!,
                                  ),
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
                            : const SizedBox.shrink(),

                        /// Edit Section button
                        if (_isEnabled(selectionProvider))
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final contentTokens = _tokenizer.organize(tokens);

                      for (var line in contentTokens) {
                        for (var word in line) {
                          for (var token in word) {
                            if (token.type == TokenType.chord) {
                              token.text = tp.transposeChord(token.text);
                            }
                          }
                        }
                      }

                      final contentWidgets = _tokenizer.buildContentWidgets(
                        contentTokens,
                        tokens,
                        layoutSettingsProvider.fontFamily,
                        section.contentColor,
                        colorScheme.onSurface,
                        _toggleDrag,
                        _addChord,
                        _addPrecedingChord,
                        _removeChordAt,
                        _isEnabled(selectionProvider),
                      );

                      final positionedWidgets = _tokenizer.positionWidgets(
                        context,
                        contentWidgets,
                        lineSpacing: 15,
                        letterSpacing: 0,
                      );

                      final content = _tokenizer.checkHumongousWords(
                        context,
                        positionedWidgets,
                      );

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: content.contentHeight,
                          child: Stack(children: [...content.tokens]),
                        ),
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
                  Navigator.pop(context); // Close the bottom sheet
                  context.read<NavigationProvider>().pushForeground(
                    EditSectionScreen(
                      versionID: widget.versionID,
                      sectionCode: widget.sectionCode,
                    ),
                  );
                },
              ),
              // duplicate
              FilledTextButton(
                text: AppLocalizations.of(context)!.duplicatePlaceholder(''),
                trailingIcon: Icons.chevron_right,
                isDiscrete: true,
                onPressed: () {
                  context.read<LocalVersionProvider>().addSectionToStruct(
                    widget.versionID ?? -1,
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
                          context.read<SectionProvider>().cacheDeleteSection(
                            widget.versionID!,
                            widget.sectionCode,
                          );
                          context
                              .read<LocalVersionProvider>()
                              .removeSectionFromStructByCode(
                                widget.versionID!,
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
