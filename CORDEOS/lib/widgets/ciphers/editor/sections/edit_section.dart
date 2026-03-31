import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/sheet_select_type.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditSectionScreen extends StatefulWidget {
  final int versionID;
  final String sectionCode;
  final bool isNewSection;
  final bool canChangeType;

  const EditSectionScreen({
    super.key,
    required this.sectionCode,
    required this.versionID,
    this.isNewSection = false,
    this.canChangeType = true,
  });

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  late TextEditingController contentCodeController;
  late TextEditingController contentTypeController;
  late TextEditingController contentTextController;
  late Color contentColor;

  @override
  void initState() {
    super.initState();

    Section section = context.read<SectionProvider>().getSection(
      widget.versionID,
      widget.sectionCode,
    )!;

    contentCodeController = TextEditingController(text: section.contentCode);
    contentTypeController = TextEditingController(text: section.contentType);
    contentTextController = TextEditingController(text: section.contentText);
    contentColor = section.contentColor;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
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
                      children: [
                        // TYPE SELECTION
                        if (widget.canChangeType)
                          SizedBox(
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
                                Expanded(
                                  child: Text(
                                    contentTypeController.text,
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _upsertSection();
                                    context
                                        .read<NavigationProvider>()
                                        .pushForeground(
                                          SelectType(
                                            versionID: widget.versionID,
                                            sectionCode: widget.sectionCode,
                                          ),
                                        );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.changePlaceholder(
                                        AppLocalizations.of(context)!.type,
                                      ),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // SECTION CODE
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.sectionCode,
                          hint: AppLocalizations.of(context)!.sectionCodeHint,
                          controller: contentCodeController,
                          instruction: AppLocalizations.of(
                            context,
                          )!.sectionCodeInstruction,
                        ),

                        // SECTION TYPE
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.sectionType,
                          hint: AppLocalizations.of(context)!.sectionTypeHint,
                          controller: contentTypeController,
                        ),

                        // SECTION TEXT
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.sectionText,
                          hint: AppLocalizations.of(context)!.sectionTextHint,
                          controller: contentTextController,
                          lineCount: 8,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
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
                            itemType: AppLocalizations.of(context)!.section,
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
        );
      },
    );
  }

  void _upsertSection() {
    // New section was added when selecting type, so just update it
    // Update the section with new values
    final newCode = context.read<SectionProvider>().cacheUpdate(
      widget.versionID,
      widget.sectionCode,
      newContentCode: contentCodeController.text,
      newContentType: contentTypeController.text,
      newContentText: contentTextController.text,
      newColor: contentColor,
    );

    // If it is a new section Add the section to the song structure
    if (widget.isNewSection) {
      context.read<LocalVersionProvider>().addSectionToStruct(
        widget.versionID,
        newCode,
      );
    }

    // If the content code has changed, update the song structure accordingly
    if (newCode != widget.sectionCode) {
      context.read<LocalVersionProvider>().updateSectionCodeInStruct(
        widget.versionID,
        oldCode: widget.sectionCode,
        newCode: newCode,
      );
      context.read<SectionProvider>().renameSectionKey(
        widget.versionID,
        oldCode: widget.sectionCode,
        newCode: newCode,
      );
    }
  }

  void _deleteSection() {
    if (widget.isNewSection) return;

    context.read<SectionProvider>().cacheDeletion(
      widget.versionID,
      widget.sectionCode,
    );
    context.read<LocalVersionProvider>().removeSectionsByCode(
      widget.versionID,
      widget.sectionCode,
    );
  }
}
