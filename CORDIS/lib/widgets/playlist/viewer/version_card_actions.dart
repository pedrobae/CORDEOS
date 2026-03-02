import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Consumer5<
      NavigationProvider,
      PlaylistProvider,
      LocalVersionProvider,
      UserProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            navigationProvider,
            playlistProvider,
            versionProvider,
            userProvider,
            authProvider,
            child,
          ) {
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;

            // Your widget build logic here
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
                        AppLocalizations.of(context)!.actionPlaceholder(
                          AppLocalizations.of(context)!.version,
                        ),
                        style: textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  // ACTIONS
                  // edit
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.editPlaceholder(''),
                    isDiscrete: true,
                    trailingIcon: Icons.chevron_right,
                    onPressed: () {
                      navigationProvider.push(
                        EditCipherScreen(
                          versionType: VersionType.playlist,
                          versionID: versionID,
                          cipherID: (versionID is String) ? null : cipherID,
                          playlistID: playlistID,
                          isEnabled: false,
                        ),
                        changeDetector: () => context.read<PlaylistProvider>().hasUnsavedChanges,
                        showBottomNavBar: true,
                      );
                      Navigator.of(context).pop();
                    },
                  ),

                  // duplicate
                  FilledTextButton(
                    text: AppLocalizations.of(
                      context,
                    )!.duplicatePlaceholder(''),
                    isDiscrete: true,
                    trailingIcon: Icons.chevron_right,
                    onPressed: () {
                      playlistProvider.cacheDuplicateVersion(
                        playlistID,
                        versionID,
                        userProvider.getLocalIdByFirebaseId(authProvider.id!)!,
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
                          return BottomSheet(
                            onClosing: () {},
                            builder: (context) {
                              return DeleteConfirmationSheet(
                                itemType: AppLocalizations.of(context)!.version,
                                isDangerous: true,
                                onConfirm: () async {
                                  playlistProvider.cacheRemoveVersion(
                                    itemID,
                                    playlistID,
                                  );
                                  // Check if version is has a duplicate in this playlist, if not, delete it entirely
                                  if (!playlistProvider.versionIsInPlaylist(
                                    versionID,
                                    playlistID,
                                  )) {
                                    await versionProvider.deleteVersion(
                                      versionID,
                                    );
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
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
          },
    );
  }
}
