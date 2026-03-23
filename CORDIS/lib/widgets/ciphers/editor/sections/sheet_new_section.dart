import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/screens/cipher/import/import_pdf.dart';
import 'package:cordis/screens/cipher/import/import_text.dart';
import 'package:cordis/widgets/ciphers/editor/sections/sheet_select_type.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewSectionSheet extends StatelessWidget {
  final int versionID;
  final int cipherID;

  const NewSectionSheet({
    super.key,
    required this.versionID,
    required this.cipherID,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.createPlaceholder(AppLocalizations.of(context)!.section),
                style: textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),

          /// MANUALLY CREATE SECTION
          FilledTextButton(
            text: AppLocalizations.of(
              context,
            )!.newPlaceholder(AppLocalizations.of(context)!.section),
            isDark: true,
            icon: Icons.add,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              Navigator.of(context).pop();
              nav.pushForeground(
                SelectType(
                  sectionCode: null,
                  versionID: versionID,
                  isNewSection: true,
                ),
              );
            },
          ),

          /// IMPORT SECTION BUTTONS
          // text
          FilledTextButton(
            text: AppLocalizations.of(context)!.importFromText,
            icon: Icons.text_snippet,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop();
              nav.push(
                () =>
                    ImportTextScreen(versionID: versionID, cipherID: cipherID),
              );
            },
          ),
          // pdf
          FilledTextButton(
            text: AppLocalizations.of(context)!.importFromPDF,
            icon: Icons.picture_as_pdf,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop();
              nav.push(
                () => ImportPdfScreen(versionID: versionID, cipherID: cipherID),
              );
            },
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }
}
