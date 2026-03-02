import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditPlaylistScreen extends StatefulWidget {
  final int? playlistId;

  const EditPlaylistScreen({super.key, this.playlistId});

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen> {
  TextEditingController playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.playlistId != null) {
      final playlistProvider = Provider.of<PlaylistProvider>(
        context,
        listen: false,
      );
      final playlist = playlistProvider.getPlaylistById(widget.playlistId!)!;
      playlistNameController.text = playlist.name;
    }
  }

  @override
  void dispose() {
    playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer4<
      NavigationProvider,
      PlaylistProvider,
      UserProvider,
      MyAuthProvider
    >(
      builder:
          (
            context,
            navigationProvider,
            playlistProvider,
            userProvider,
            authProvider,
            child,
          ) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 32,
                children: [
                  // HEADER
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.namePlaylistPrompt,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (widget.playlistId == null)
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.createPlaylistInstructions,
                          style: theme.textTheme.bodyLarge,
                        ),
                    ],
                  ),
                  // FORM
                  LabeledTextField(
                    label: AppLocalizations.of(context)!.playlistNameLabel,
                    controller: playlistNameController,
                    hint: AppLocalizations.of(context)!.playlistNameHint,
                  ),

                  // ACTIONS
                  Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledTextButton(
                        text: widget.playlistId != null
                            ? AppLocalizations.of(context)!.save
                            : AppLocalizations.of(context)!.create,
                        isDark: true,
                        onPressed: () async {
                          widget.playlistId != null
                              ? await playlistProvider.updateName(
                                  widget.playlistId!,
                                  playlistNameController.text,
                                )
                              : await playlistProvider.createPlaylist(
                                  playlistNameController.text,
                                  userProvider.getLocalIdByFirebaseId(
                                    authProvider.id!,
                                  )!,
                                );
                          navigationProvider.pop();
                        },
                      ),
                      FilledTextButton(
                        text: AppLocalizations.of(context)!.cancel,
                        onPressed: () {
                          navigationProvider.attemptPop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
    );
  }
}
