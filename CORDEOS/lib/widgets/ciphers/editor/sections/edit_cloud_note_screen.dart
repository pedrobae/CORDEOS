import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CloudNoteScreen extends StatefulWidget {
  final String firebaseVersionID;
  final CloudVersionNote? note;

  const CloudNoteScreen({
    super.key,
    required this.firebaseVersionID,
    this.note,
  });

  @override
  State<CloudNoteScreen> createState() => _CloudNoteScreenState();
}

class _CloudNoteScreenState extends State<CloudNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.content);
    _textController = TextEditingController(text: widget.note?.content);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

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
                        nav.attemptPop(context);
                      },
                    ),
                    Text(
                      AppLocalizations.of(context)!.editPlaceholder(
                        AppLocalizations.of(context)!.annotations,
                      ),
                      style: textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () {
                        _upsertAnnotation();
                        nav.pop();
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
                        // SECTION TYPE
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.title,
                          hint: AppLocalizations.of(context)!.titleHint,
                          controller: _titleController,
                          textCapitalization: TextCapitalization.words,
                        ),

                        // SECTION TEXT
                        LabeledTextField(
                          label: AppLocalizations.of(
                            context,
                          )!.sectionAnnotations,
                          hint: AppLocalizations.of(
                            context,
                          )!.sectionAnnotations,
                          controller: _textController,
                          lineCount: 8,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        // DELETE BUTTON
                        if (widget.note != null)
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
                                      _deleteAnnotation();
                                      nav.pop();
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

  void _upsertAnnotation() {
    final cloudVer = context.read<CloudVersionProvider>();
    if (widget.note != null) {
      cloudVer.update(
        0,
        widget.note!.copyWith(
          content: _textController.text,
          title: _titleController.text,
        ),
      );
    } else {
      cloudVer.create(
        0,
        _textController.text,
        _titleController.text,
        widget.firebaseVersionID,
      );
    }
  }

  void _deleteAnnotation() async {
    if (widget.note == null) return;
    await context.read<CloudVersionProvider>().delete(
      widget.note!.firebaseVersionID,
      widget.note!.id,
    );
  }
}
