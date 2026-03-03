import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
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
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final play = Provider.of<PlaylistProvider>(context, listen: false);

    return Scaffold(
      appBar: _buildAppBar(nav),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 32,
          children: [
            _buildInstructionsSection(),
            _buildNameField(),
            _buildActionButtons(play, nav),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(NavigationProvider nav) {
    final theme = Theme.of(context);
    return AppBar(
      leading: BackButton(onPressed: () => nav.attemptPop(context)),
      title: Text(
        AppLocalizations.of(context)!.namePlaylistPrompt,
        style: theme.textTheme.titleMedium,
      ),
    );
  }

  Widget _buildInstructionsSection() {
    final theme = Theme.of(context);
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.playlistId == null)
          Text(
            AppLocalizations.of(context)!.createPlaylistInstructions,
            style: theme.textTheme.bodyLarge,
          ),
      ],
    );
  }

  Widget _buildNameField() {
    return LabeledTextField(
      label: AppLocalizations.of(context)!.playlistNameLabel,
      controller: playlistNameController,
      hint: AppLocalizations.of(context)!.playlistNameHint,
    );
  }

  Widget _buildActionButtons(PlaylistProvider play, NavigationProvider nav) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledTextButton(
          text: widget.playlistId != null
              ? AppLocalizations.of(context)!.save
              : AppLocalizations.of(context)!.create,
          isDark: true,
          onPressed: () => _handleSave(play, nav),
        ),
        FilledTextButton(
          text: AppLocalizations.of(context)!.cancel,
          onPressed: () => nav.attemptPop(context),
        ),
      ],
    );
  }

  Future<void> _handleSave(
    PlaylistProvider play,
    NavigationProvider nav,
  ) async {
    if (widget.playlistId != null) {
      await play.updateName(widget.playlistId!, playlistNameController.text);
    } else {
      final localId = Provider.of<MyAuthProvider>(
        context,
        listen: false,
      ).userLocalId!;
      await play.createPlaylist(playlistNameController.text, localId);
    }

    nav.pop();
  }
}
