import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/selection_provider.dart';

import 'package:cordis/screens/cipher/cipher_library.dart';

import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_editor.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final int playlistID;

  const AddToPlaylistSheet({super.key, required this.playlistID});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final sel = context.read<SelectionProvider>();

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
          // ADD SONG TO PLAYLIST
          FilledTextButton(
            text: AppLocalizations.of(
              context,
            )!.addPlaceholder(AppLocalizations.of(context)!.cipher),
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              // Enable selection mode
              sel.enableSelectionMode();
              sel.setTarget(playlistID);

              // Close the bottom sheet
              Navigator.of(context).pop();

              // Navigate to Cipher Library Screen
              nav.push(
                () => CipherLibraryScreen(),
                showBottomNavBar: true,
                onPopCallback: () {
                  // Disable selection mode when returning
                  sel.disableSelectionMode();
                  sel.clearTarget();
                },
              );
            },
          ),
          // ADD FLOW ITEM TO PLAYLIST
          FilledTextButton(
            text: AppLocalizations.of(
              context,
            )!.addPlaceholder(AppLocalizations.of(context)!.flowItem),
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              final flow = context.read<FlowItemProvider>();

              Navigator.of(context).pop();
              nav.push(
                () => FlowItemEditor(flowID: -1, playlistID: playlistID ),
                changeDetector: () => flow.hasUnsavedChanges,
                onChangeDiscarded: () => flow.loadFlowItem(-1),
                showBottomNavBar: true,
              );
            },
          ),
          SizedBox(),
        ],
      ),
    );
  }
}
