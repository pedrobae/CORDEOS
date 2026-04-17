import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/utils/section_constants.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/select_type.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditSectionScreen extends StatefulWidget {
  final int versionID;
  final int sectionKey;
  final bool isNewSection;
  final bool canChangeType;

  const EditSectionScreen({
    super.key,
    required this.sectionKey,
    required this.versionID,
    this.isNewSection = false,
    this.canChangeType = true,
  });

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  late TextEditingController contentTypeController;
  late TextEditingController contentTextController;
  late Color contentColor;

  @override
  void initState() {
    super.initState();

    Section section = context.read<SectionProvider>().getSection(
      versionKey: widget.versionID,
      sectionKey: widget.sectionKey,
    )!;

    contentTypeController = TextEditingController(text: section.contentType);
    contentTextController = TextEditingController(text: section.contentText);
    contentColor = section.contentColor;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        double keyboardInset = media.viewInsets.bottom;
        final screenHeight = media.size.height;
        final renderObject = context.findRenderObject();

        if (renderObject is RenderBox && renderObject.hasSize) {
          final globalBottom = renderObject
              .localToGlobal(Offset(0, renderObject.size.height))
              .dy;
          final bottomGap = (screenHeight - globalBottom);
          keyboardInset = (keyboardInset - bottomGap).clamp(0.0, keyboardInset);
        }

        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BackButton(
                      color: colorScheme.onSurface,
                      onPressed: () {
                        if (widget.isNewSection) {
                          // If it's a new section,
                          // Delete the cached section that was created when selecting type
                          _deleteSection();
                        }
                        context.read<NavigationProvider>().attemptPop(context);
                      },
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.editPlaceholder(AppLocalizations.of(context)!.section),
                      style: textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () {
                        _upsertSection();
                        context.read<NavigationProvider>().pop();
                      },
                      icon: Icon(Icons.save, size: 30),
                    ),
                  ],
                ),

                // CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      spacing: 16,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TYPE SELECTION
                        if (widget.canChangeType)
                          GestureDetector(
                            onTap: () {
                              _upsertSection();
                              context.read<NavigationProvider>().pushForeground(
                                SelectType(
                                  versionID: widget.versionID,
                                  sectionKey: widget.sectionKey,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: BoxBorder.all(
                                  color: colorScheme.surfaceContainerLowest,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Container(
                                    height: 28,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: contentColor,
                                    ),
                                  ),
                                  Selector<SectionProvider, String>(
                                    selector: (context, sect) {
                                      final section = sect.getSection(
                                        versionKey: widget.versionID,
                                        sectionKey: widget.sectionKey,
                                      );
                                      return section?.sectionType
                                              .localizedLabel(context) ??
                                          '';
                                    },
                                    builder:
                                        (context, sectionTypeLabel, child) {
                                          return Expanded(
                                            child: Text(
                                              sectionTypeLabel,
                                              style: textTheme.bodyLarge,
                                            ),
                                          );
                                        },
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 28,
                                    color: colorScheme.onSurface,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // SECTION TYPE
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.sectionType,
                          hint: AppLocalizations.of(context)!.sectionTypeHint,
                          controller: contentTypeController,
                          textCapitalization: TextCapitalization.words,
                        ),

                        // SECTION TEXT
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.sectionText,
                          hint: AppLocalizations.of(context)!.sectionTextHint,
                          controller: contentTextController,
                          lineCount: 8,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        // DELETE BUTTON
                        if (!widget.isNewSection)
                          FilledTextButton(
                            text: AppLocalizations.of(context)!.delete,
                            isDangerous: true,
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return DeleteConfirmationSheet(
                                    itemType: AppLocalizations.of(
                                      context,
                                    )!.section,
                                    onConfirm: () {
                                      _deleteSection();
                                      context.read<NavigationProvider>().pop();
                                    },
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _upsertSection() {
    // New section was added when selecting type, so just update it
    // Update the section with new values
    context.read<SectionProvider>().cacheUpdate(
      widget.versionID,
      widget.sectionKey,
      newContentType: contentTypeController.text,
      newContentText: contentTextController.text,
    );
  }

  void _deleteSection() {
    if (widget.isNewSection) return;

    context.read<SectionProvider>().cacheDeletion(
      widget.versionID,
      widget.sectionKey,
    );
    context.read<LocalVersionProvider>().removeSectionsByKey(
      widget.versionID,
      widget.sectionKey,
    );
  }
}
