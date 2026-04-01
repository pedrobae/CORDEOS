import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/edit_cipher.dart';
import 'package:cordeos/screens/cipher/import/import_pdf.dart';
import 'package:cordeos/screens/cipher/import/import_text.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewSongSheet extends StatelessWidget {
  const NewSongSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final auth = context.read<MyAuthProvider>();

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
                )!.createPlaceholder(AppLocalizations.of(context)!.cipher),
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

          /// MANUALLY CREATE SONG
          FilledTextButton(
            text: AppLocalizations.of(context)!.createManually,
            isDark: true,
            icon: Icons.add,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              final ciph = context.read<CipherProvider>();
              final localVer = context.read<LocalVersionProvider>();

              Navigator.of(context).pop();
              nav.push(
                () => const EditCipherScreen(
                  cipherID: -1,
                  versionID: -1,
                  versionType: VersionType.brandNew,
                ),
                changeDetector: () {
                  return ciph.hasUnsavedChanges || localVer.hasUnsavedChanges;
                },
                onChangeDiscarded: () {
                  ciph.clearCipherFromCache();
                  localVer.clearVersionFromCache();
                },
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
              nav.push(() => const ImportTextScreen());
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
              nav.push(() => const ImportPdfScreen());
            },
          ),
          // image
          if (auth.isAdmin)
            FilledTextButton(
              text: AppLocalizations.of(context)!.importFromImage,
              icon: Icons.image,
              trailingIcon: Icons.chevron_right,
              isDiscrete: true,
              onPressed: () {
                // for now show coming soon snackbar from the settings screen
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.amberAccent,
                    content: Text(
                      'Funcionalidade em desenvolvimento,',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }
}
