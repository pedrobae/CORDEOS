import 'package:cordeos/helpers/chords.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContentFilters extends StatefulWidget {
  const ContentFilters({super.key});

  @override
  State<ContentFilters> createState() => _ContentFiltersState();
}

class _ContentFiltersState extends State<ContentFilters> {
  bool showChordCustomization = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<LayoutSetProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
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
                _buildChordSettings(context),

                _buildFilterToggle(
                  textTheme,
                  label: l10n.repeatSections,
                  value: settings.showRepeatSections,
                  onChanged: (_) async => await settings.toggleRepeatSections(),
                ),
                _buildFilterToggle(
                  textTheme,
                  label: l10n.notes,
                  value: settings.showAnnotations,
                  onChanged: (_) async => await settings.toggleAnnotations(),
                ),
                _buildFilterToggle(
                  textTheme,
                  label: l10n.transitions,
                  value: settings.showTransitions,
                  onChanged: (_) async => await settings.toggleTransitions(),
                ),
                _buildFilterToggle(
                  textTheme,
                  label: l10n.lyrics,
                  value: settings.showLyrics,
                  onChanged: (_) async => await settings.toggleLyrics(),
                ),
                SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChordSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final laySet = context.read<LayoutSetProvider>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            offset: Offset(2, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: showChordCustomization
            ? Column(
                key: const ValueKey('expanded'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  SizedBox(),
                  GestureDetector(
                    onTap: () => setState(() => showChordCustomization = false),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: 0.25,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Icon(Icons.chevron_right),
                        ),
                        Expanded(
                          child: Text(l10n.chords, style: textTheme.labelLarge),
                        ),
                        // Example chord
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (Chord.fromString('C#m7/E').string(
                              showBass: laySet.showChordBass,
                              showAddedNote: laySet.showAddedNotes,
                            )),
                            style: laySet.chordStyle.copyWith(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.surfaceContainerLowest),
                  Row(
                    children: [
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.chordBass,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Switch(
                        value: laySet.showChordBass,
                        onChanged: (_) async => await laySet.toggleChordBass(),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.addedNotes,
                          style: textTheme.labelLarge,
                        ),
                      ),
                      Switch(
                        value: laySet.showAddedNotes,
                        onChanged: (_) async => await laySet.toggleAddedNotes(),
                      ),
                    ],
                  ),
                ],
              )
            : GestureDetector(
                key: const ValueKey('collapsed'),

                onTap: () => setState(() {
                  showChordCustomization = true;
                }),
                child: _buildFilterToggle(
                  textTheme,
                  label: l10n.chords,
                  value: laySet.showChords,
                  onChanged: (_) async => await laySet.toggleChords(),
                ),
              ),
      ),
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
