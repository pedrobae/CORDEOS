import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/import/import_pdf.dart';
import 'package:cordeos/screens/cipher/import/import_text.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/select_type.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewSectionSheet extends StatelessWidget {
  final int versionID;

  const NewSectionSheet({super.key, required this.versionID});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final cipherID = context
        .read<LocalVersionProvider>()
        .getVersion(versionID)!
        .cipherID;
    final nav = context.read<NavigationProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
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
                nav.push(
                  () => SelectType(
                    sectionKey: null,
                    versionID: versionID,
                    isNewSection: true,
                  ),
                  showBottomNavBar: true,
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
                  () => ImportTextScreen(
                    versionID: versionID,
                    cipherID: cipherID != -1
                        ? cipherID
                        : -2, // Pass -2 to trigger import instead of create flow
                  ),
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
                  () => ImportPdfScreen(
                    versionID: versionID,
                    cipherID: cipherID != -1
                        ? cipherID
                        : -2, // Pass -2 to trigger import instead of create flow
                  ),
                );
              },
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
