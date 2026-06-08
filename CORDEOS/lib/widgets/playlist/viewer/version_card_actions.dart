import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/screens/cipher/edit_cipher.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';

import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class VersionCardActionsSheet extends StatelessWidget {
  final int playlistID;
  final int versionID;
  final int cipherID;
  final int itemID;

  const VersionCardActionsSheet({
    super.key,
    required this.versionID,
    required this.playlistID,
    required this.cipherID,
    required this.itemID,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final auth = context.read<MyAuthProvider>();
    final user = context.read<UserProvider>();
    final play = context.read<PlaylistProvider>();
    final localVer = context.read<LocalVersionProvider>();

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
                l10n.actionPlaceholder(l10n.version),
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          // Version Notes
          Selector<LocalVersionProvider, String?>(
            selector: (context, localVer) =>
                localVer.getVersion(versionID)?.notes,
            builder: (context, notes, child) {
              if (notes == null) return SizedBox();
              return Text(notes, style: textTheme.bodyMedium);
            },
          ),

          // ACTIONS
          // edit
          FilledTextButton(
            text: l10n.editPlaceholder(''),
            isDiscrete: true,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              final nav = context.read<NavigationProvider>();
              final localVer = context.read<LocalVersionProvider>();
              final sect = context.read<SectionProvider>();

              nav.push(
                () => EditCipherScreen(
                  versionID: versionID,
                  cipherID: cipherID,
                  versionType: VersionType.playlist,
                ),
                changeDetector: () =>
                    localVer.hasUnsavedChanges || sect.hasUnsavedChanges,
                onChangeDiscarded: () async {
                  await localVer.loadVersion(versionID);
                  await sect.loadSectionsOfVersion(versionID);
                },
              );
              Navigator.of(context).pop();
            },
          ),

          // duplicate
          FilledTextButton(
            text: l10n.duplicatePlaceholder(''),
            isDiscrete: true,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              play.cacheDuplicateVersion(
                playlistID,
                versionID,
                user.getLocalIdByFirebaseId(auth.id!)!,
              );
              Navigator.of(context).pop();
            },
          ),
          // delete
          FilledTextButton(
            text: l10n.delete,
            isDangerous: true,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return DeleteConfirmationSheet(
                    itemType: l10n.version,
                    isDangerous: true,
                    onConfirm: () {
                      // Count occurrences BEFORE removing to check if this is the only one
                      final playlist = play.getPlaylist(playlistID);
                      final occurrences =
                          playlist?.items
                              .where((item) => item.contentId == versionID)
                              .length ??
                          0;

                      play.cacheRemoveVersion(itemID, playlistID);

                      // If this was the only occurrence, delete the version
                      if (occurrences <= 1) {
                        localVer.cacheDeletion(versionID);
                      }
                      Navigator.of(context).pop();
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
