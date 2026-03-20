import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTagSheet extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;

  const AddTagSheet({
    super.key,
    this.cipherID,
    this.versionID,
    required this.versionType,
  });

  @override
  State<AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<AddTagSheet> {
  TextEditingController tagController = TextEditingController();

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final ciph = context.read<CipherProvider>();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.addPlaceholder(AppLocalizations.of(context)!.tag),
                  style: textTheme.titleMedium,
                ),
                CloseButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),

            // CREATE TAG INPUT
            TextFormField(
              controller: tagController,
              decoration: InputDecoration(
                visualDensity: VisualDensity.compact,
                hintText: AppLocalizations.of(context)!.tagHint,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(
                    color: colorScheme.surfaceContainerLowest,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            FilledTextButton(
              text: AppLocalizations.of(context)!.addPlaceholder(''),
              isDark: true,
              onPressed: () {
                switch (widget.versionType) {
                  case VersionType.playlist:
                    throw Exception('Cannot add tags to playlist versions');
                  case VersionType.brandNew:
                  case VersionType.import:
                  case VersionType.local:
                    ciph.cacheAddTag(
                      widget.cipherID ?? -1,
                      tagController.text.trim(),
                    );
                  case VersionType.cloud:
                    throw Exception(
                      'Cannot add tags to cloud versions. Please save the version locally first.',
                    );
                }
                Navigator.of(context).pop();
              },
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
