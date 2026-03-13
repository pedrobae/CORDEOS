import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';

import 'package:cordis/screens/playlist/edit_playlist.dart';
import 'package:cordis/screens/schedule/create.dart';
import 'package:cordis/screens/schedule/share_code_screen.dart';

import 'package:cordis/widgets/ciphers/library/sheet_new_song.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final sel = context.read<SelectionProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.quickAction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),

          // ACTIONS
          // DIRECT CREATION BUTTONS
          /// create playlist
          FilledTextButton(
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            text: AppLocalizations.of(
              context,
            )!.createPlaceholder(AppLocalizations.of(context)!.playlist),
            onPressed: () {
              final playlistProvider = context.read<PlaylistProvider>();
              Navigator.of(context).pop(); // Close the bottom sheet
              nav.attemptPop(context, route: NavigationRoute.playlists);
              nav.push(
                () => EditPlaylistScreen(),
                changeDetector: () => playlistProvider.hasUnsavedChanges,
                showBottomNavBar: true,
              );
            },
          ),
          // create song
          FilledTextButton(
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            text: AppLocalizations.of(
              context,
            )!.addPlaceholder(AppLocalizations.of(context)!.cipher),
            onPressed: () {
              Navigator.of(context).pop(); // Close the bottom sheet
              nav.attemptPop(context, route: NavigationRoute.library);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => NewSongSheet(),
              );
            },
          ),
          FilledTextButton(
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            text: AppLocalizations.of(context)!.assignSchedule,
            onPressed: () {
              final localScheduleProvider = context
                  .read<LocalScheduleProvider>();
              Navigator.of(context).pop(); // Close the bottom sheet
              nav.attemptPop(context, route: NavigationRoute.schedule);
              sel.enableSelectionMode();
              nav.push(
                () => CreateScheduleScreen(creationStep: 1),
                showBottomNavBar: true,
                changeDetector: () => localScheduleProvider.hasUnsavedChanges,
                onPopCallback: () {
                  sel.disableSelectionMode();
                },
              );
            },
          ),
          FilledTextButton(
            text: AppLocalizations.of(context)!.enterShareCode,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              Navigator.of(context).pop(); // Close the bottom sheet
              nav.push(
                () => ShareCodeScreen(
                  onBack: (_) {
                    nav.attemptPop(context); // Close the share code screen
                  },
                  onSuccess: (_) {
                    nav.pop(); // Close the share code screen
                  },
                ),
                showBottomNavBar: true,
                showAppBar: true,
                showDrawerIcon: true,
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
