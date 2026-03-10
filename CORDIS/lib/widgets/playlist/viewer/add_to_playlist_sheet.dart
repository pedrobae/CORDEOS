import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/cipher/cipher_library.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final int playlistId;

  const AddToPlaylistSheet({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, SelectionProvider>(
      builder: (context, navigationProvider, selectionProvider, child) {
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
                    AppLocalizations.of(context)!.quickAction,
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface,
                      size: 32,
                    ),
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
                  selectionProvider.enableSelectionMode();
                  selectionProvider.setTarget(playlistId);

                  // Close the bottom sheet
                  Navigator.of(context).pop();

                  // Navigate to Cipher Library Screen
                  navigationProvider.push(
                    () => CipherLibraryScreen(),
                    showBottomNavBar: true,

                    onPopCallback: () {
                      // Disable selection mode when returning
                      selectionProvider.disableSelectionMode();
                      selectionProvider.clearTarget();
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
                  Navigator.of(context).pop();
                  navigationProvider.push(
                    () => FlowItemEditor(playlistId: playlistId),
                    showBottomNavBar: true,
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
