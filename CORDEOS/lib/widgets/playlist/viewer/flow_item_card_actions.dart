import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';

import 'package:cordeos/widgets/common/filled_text_button.dart';

class FlowItemCardActionsSheet extends StatelessWidget {
  final int flowItemId;
  final int playlistId;

  const FlowItemCardActionsSheet({
    super.key,
    required this.flowItemId,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final flow = context.read<FlowItemProvider>();
    final play = context.read<PlaylistProvider>();

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
                AppLocalizations.of(
                  context,
                )!.actionPlaceholder(AppLocalizations.of(context)!.flowItem),
                style: textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(Icons.close, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // ACTIONS
          // DUPLICATE FLOW ITEM
          FilledTextButton(
            text: AppLocalizations.of(context)!.duplicatePlaceholder(''),
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            onPressed: () {
              flow.duplicateFlowItem(
                flowItemId,
                '(${AppLocalizations.of(context)!.copy})',
                play.getPlaylist(playlistId)!.items.length,
              );
            },
          ),
          // DELETE FLOW ITEM
          FilledTextButton(
            text: AppLocalizations.of(context)!.delete,
            trailingIcon: Icons.chevron_right,
            isDiscrete: true,
            isDangerous: true,
            onPressed: () {
              flow.cacheDeletion(flowItemId);
            },
          ),
          SizedBox(),
        ],
      ),
    );
  }
}
