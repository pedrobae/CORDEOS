import 'package:cordeos/widgets/ciphers/editor/sections/sheet_manage.dart';
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
                AppLocalizations.of(
                  context,
                )!.actionPlaceholder(AppLocalizations.of(context)!.version),
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
            text: AppLocalizations.of(context)!.editPlaceholder(''),
            isDiscrete: true,
            trailingIcon: Icons.chevron_right,
            onPressed: () => _showManageSheet(context),
          ),

          // duplicate
          FilledTextButton(
            text: AppLocalizations.of(context)!.duplicatePlaceholder(''),
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
            text: AppLocalizations.of(context)!.delete,
            isDangerous: true,
            trailingIcon: Icons.chevron_right,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return DeleteConfirmationSheet(
                    itemType: AppLocalizations.of(context)!.version,
                    isDangerous: true,
                    onConfirm: () {
                      play.cacheRemoveVersion(itemID, playlistID);
                      // Check if version has a duplicate in this playlist
                      // If not, delete it
                      if (!play.versionIsInPlaylist(versionID, playlistID)) {
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

  void _showManageSheet(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (context) {
        return ManageSheet(versionID: versionID, playlistMode: true);
      },
    );
  }
}
