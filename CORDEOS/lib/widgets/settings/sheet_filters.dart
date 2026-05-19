import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/widgets/settings/chord_customization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContentFilters extends StatelessWidget {
  const ContentFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                  Text(l10n.contentFilters, style: textTheme.titleMedium),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // FILTERS
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => ChordCustomization(),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(
                      color: colorScheme.surfaceContainerLowest,
                      width: 1,
                    ),
                  ),
                  child: _buildFilterToggle(
                    textTheme,
                    label: l10n.chords,
                    value: settings.showChords,
                    onChanged: (_) => settings.toggleChords(),
                  ),
                ),
              ),
              _buildFilterToggle(
                textTheme,
                label: l10n.repeatSections,
                value: settings.showRepeatSections,
                onChanged: (_) => settings.toggleRepeatSections(),
              ),
              _buildFilterToggle(
                textTheme,
                label: l10n.notes,
                value: settings.showAnnotations,
                onChanged: (_) => settings.toggleAnnotations(),
              ),
              _buildFilterToggle(
                textTheme,
                label: l10n.transitions,
                value: settings.showTransitions,
                onChanged: (_) => settings.toggleTransitions(),
              ),
              _buildFilterToggle(
                textTheme,
                label: l10n.lyrics,
                value: settings.showLyrics,
                onChanged: (_) => settings.toggleLyrics(),
              ),
              SizedBox(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterToggle(
    TextTheme textTheme, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(Icons.chevron_right),
        Expanded(child: Text(label, style: textTheme.labelLarge)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
