import 'package:cordeos/helpers/chords.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChordCustomization extends StatelessWidget {
  const ChordCustomization({super.key});

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
                  Text(l10n.chordCustomization, style: textTheme.titleMedium),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // Example chord
              Center(
                child: Text(
                  (Chord.fromString('C#m7/E').string(
                    showBass: settings.showChordBass,
                    showAddedNote: settings.showAddedNotes,
                  )),
                  style: settings.chordStyle,
                ),
              ),

              // FILTERS
              _buildFilterToggle(
                context,
                label: l10n.chordBass,
                value: settings.showChordBass,
                onChanged: (_) => settings.toggleChordBass(),
              ),
              _buildFilterToggle(
                context,
                label: l10n.addedNotes,
                value: settings.showAddedNotes,
                onChanged: (_) => settings.toggleAddedNotes(),
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
