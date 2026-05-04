import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/widgets/ciphers/library/sheet_export.dart';
import 'package:cordeos/widgets/ciphers/library/sheet_links.dart';
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
  final int cipherID;
  final VersionType versionType;

  const CipherCardActionsSheet({
    super.key,
    required this.cipherID,
    required this.versionType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final nav = context.read<NavigationProvider>();
    final ciph = context.read<CipherProvider>();
    final sect = context.read<SectionProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    final links = ciph.ciphers[cipherID]?.links;

    final versionID = localVer.getIdOfOldestVersionOfCipher(cipherID);

    if (versionID == null) {
      // This should never happen, but just in case
      return Container(
        padding: const EdgeInsets.all(16.0),
        color: colorScheme.surface,
        child: Text(
          l10n.error,
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
                l10n.quickAction,
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
            text: AppLocalizations.of(context)!.editPlaceholder(l10n.cipher),
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop(); // Close the bottom sheet
              nav.push(
                () => EditCipherScreen(
                  versionID: versionID,
                  versionType: versionType,
                  cipherID: cipherID,
                  isEnabled: versionType == VersionType.local,
                ),
                keepAlive: true,
                changeDetector: () =>
                    localVer.hasUnsavedChanges ||
                    ciph.hasUnsavedChanges ||
                    sect.hasUnsavedChanges,
                onChangeDiscarded: () {
                  localVer.loadVersion(versionID);
                  ciph.loadCipher(cipherID);
                  sect.loadSectionsOfVersion(versionID);
                },
              );
            },
          ),
          FilledTextButton(
            text: l10n.export,
            onPressed: () {
              Navigator.of(context).pop();
              _openExportSheet(context, versionID);
            },
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
          ),
          if (links != null &&
              links.any((link) {
                return link.isNotEmpty;
              }))
            FilledTextButton(
              text: l10n.openLink,
              trailingIcon: Icons.chevron_right,
              isDiscrete: true,
              onPressed: _openLinksSheet(links, context),
            ),
          // SELECT VERSION
          // Only show if there are multiple versions available
          if (localVer.getVersionsByCipherId(cipherID).length > 1)
            FilledTextButton(
              text: AppLocalizations.of(
                context,
              )!.selectPlaceholder(l10n.version),
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
                        return SelectVersionSheet(cipherId: cipherID);
                      },
                    );
                  },
                );
              },
            ),
          // DELETE CIPHER
          FilledTextButton(
            text: l10n.delete,
            tooltip: l10n.deleteCipherDescription,
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
                        itemType: l10n.cipher,
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          final version = localVer.getVersion(versionID)!;
                          if (version.firebaseID != null &&
                              version.firebaseID!.isNotEmpty) {
                            await cloudVer.ensureVersionIsLoaded(
                              version.firebaseID!,
                            );
                          }

                          await ciph.deleteCipher(cipherID);
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

  VoidCallback _openLinksSheet(List<String> links, context) {
    return () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return BottomSheet(
            shape: LinearBorder(),
            onClosing: () {},
            builder: (context) {
              return LinksSheet(links: links);
            },
          );
        },
      );
    };
  }

  void _openExportSheet(context, int versionID) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BottomSheet(
          shape: LinearBorder(),
          onClosing: () {},
          builder: (context) {
            return ExportSheet(versionID: versionID);
          },
        );
      },
    );
  }
}
