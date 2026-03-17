import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContentFilters extends StatelessWidget {
  const ContentFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<LayoutSetProvider>(
      builder: (context, settings, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              // HEADER
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.contentFilters,
                    style: textTheme.titleMedium,
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // FILTERS
              _buildFilterToggle(
                context,
                label: AppLocalizations.of(context)!.chords,
                value: settings.contentFilters[ContentFilter.chords] ?? false,
                onChanged: (_) => settings.toggleChords(),
              ),

              _buildFilterToggle(
                context,
                label: AppLocalizations.of(context)!.lyrics,
                value: settings.contentFilters[ContentFilter.lyrics] ?? false,
                onChanged: (_) => settings.toggleLyrics(),
              ),

              _buildFilterToggle(
                context,
                label: AppLocalizations.of(context)!.notes,
                value: settings.layoutFilters[LayoutFilter.annotations] ?? false,
                onChanged: (_) => settings.toggleNotes(),
              ),
              _buildFilterToggle(
                context,
                label: AppLocalizations.of(context)!.transitions,
                value: settings.layoutFilters[LayoutFilter.transitions] ?? false,
                onChanged: (_) => settings.toggleTransitions(),
              ),
              SizedBox(),
            ],
          ),
        );
      },
    );
  }

  Row _buildFilterToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(Icons.chevron_right),
        Expanded(child: Text(label, style: textTheme.labelLarge)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
