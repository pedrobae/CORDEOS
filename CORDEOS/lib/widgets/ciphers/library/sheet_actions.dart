import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

import 'package:cordeos/screens/cipher/edit_cipher.dart';

import 'package:cordeos/widgets/ciphers/library/sheet_select_version.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class CipherCardActionsSheet extends StatelessWidget {
  final int cipherId;
  final VersionType versionType;

  const CipherCardActionsSheet({
    super.key,
    required this.cipherId,
    required this.versionType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    final link = ciph.ciphers[cipherId]?.link;

    final versionID = localVer.getIdOfOldestVersionOfCipher(cipherId);

    if (versionID == null) {
      // This should never happen, but just in case
      return Container(
        padding: const EdgeInsets.all(16.0),
        color: colorScheme.surface,
        child: Text(
          AppLocalizations.of(context)!.error,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: colorScheme.surface,
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
                textAlign: TextAlign.center,
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // ACTIONS
          // EDIT CIPHER
          FilledTextButton(
            text: AppLocalizations.of(
              context,
            )!.editPlaceholder(AppLocalizations.of(context)!.cipher),
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop(); // Close the bottom sheet
              nav.push(
                () => EditCipherScreen(
                  versionID: versionID,
                  versionType: versionType,
                  cipherID: cipherId,
                  isEnabled: versionType == VersionType.local,
                ),
                keepAlive: true,
                changeDetector: () =>
                    localVer.hasUnsavedChanges || ciph.hasUnsavedChanges,
                onChangeDiscarded: () {
                  localVer.loadVersion(versionID);
                  ciph.loadCipher(cipherId);
                },
              );
            },
          ),
          if (link != null && link.isNotEmpty)
            FilledTextButton(
              text: AppLocalizations.of(context)!.openLink,
              tooltip: link,
              trailingIcon: Icons.open_in_new,
              isDiscrete: true,
              onPressed: () async {
                // Open the cipher's link in the default browser
                final url = ciph.ciphers[cipherId]!.link!;
                await nav.launchURL(url);
              },
            ),
          // SELECT VERSION
          // Only show if there are multiple versions available
          if (localVer.getVersionsByCipherId(cipherId).length > 1)
            FilledTextButton(
              text: AppLocalizations.of(
                context,
              )!.selectPlaceholder(AppLocalizations.of(context)!.version),
              trailingIcon: Icons.chevron_right,
              isDiscrete: true,
              onPressed: () {
                Navigator.of(context).pop(); // Close the bottom sheet
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return BottomSheet(
                      shape: LinearBorder(),
                      onClosing: () {},
                      builder: (context) {
                        return SelectVersionSheet(cipherId: cipherId);
                      },
                    );
                  },
                );
              },
            ),
          // DELETE CIPHER
          FilledTextButton(
            text: AppLocalizations.of(context)!.delete,
            tooltip: AppLocalizations.of(context)!.deleteCipherDescription,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            isDangerous: true,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return BottomSheet(
                    shape: LinearBorder(),
                    onClosing: () {},
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.cipher,
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          final version = localVer.getVersion(versionID)!;
                          if (version.firebaseID != null &&
                              version.firebaseID!.isNotEmpty) {
                            await cloudVer.ensureVersionIsLoaded(
                              version.firebaseID!,
                            );
                          }

                          await ciph.deleteCipher(cipherId);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          SizedBox(),
        ],
      ),
    );
  }
}
