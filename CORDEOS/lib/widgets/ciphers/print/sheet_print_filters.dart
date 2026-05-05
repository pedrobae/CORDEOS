import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrintFilters extends StatefulWidget {
  const PrintFilters({super.key});

  @override
  State<PrintFilters> createState() => _PrintFiltersState();
}

class _PrintFiltersState extends State<PrintFilters> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final print = context.read<PrintingProvider>();

    return Selector<
      PrintingProvider,
      ({
        bool showHeader,
        bool showSongMap,
        bool showBpm,
        bool showDuration,
        bool showSectionLabels,
        bool showRepeatSections,
        bool showAnnotations,
        bool showChords,
        bool showLyrics,
      })
    >(
      selector: (context, print) => (
        showHeader: print.showHeader,
        showSongMap: print.showSongMap,
        showBpm: print.showBpm,
        showDuration: print.showDuration,
        showSectionLabels: print.showSectionLabels,
        showRepeatSections: print.showRepeatSections,
        showAnnotations: print.showAnnotations,
        showChords: print.showChords,
        showLyrics: print.showLyrics,
      ),
      builder: (context, s, child) => Container(
        color: colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Container(
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        _buildFilterToggle(
                          context,
                          label: l10n.header,
                          value: s.showHeader,
                          onChanged: (_) async {
                            await print.toggleHeader();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.chords,
                          value: s.showChords,
                          onChanged: (_) async {
                            await print.toggleChords();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.lyrics,
                          value: s.showLyrics,
                          onChanged: (_) async {
                            await print.toggleLyrics();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.songStructure,
                          value: s.showSongMap,
                          onChanged: (_) async {
                            await print.toggleSongMap();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.bpm,
                          value: s.showBpm,
                          onChanged: (_) async {
                            await print.toggleBpm();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.duration,
                          value: s.showDuration,
                          onChanged: (_) async {
                            await print.toggleDuration();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.sectionLabels,
                          value: s.showSectionLabels,
                          onChanged: (_) async {
                            await print.toggleSectionLabels();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.repeatSections,
                          value: s.showRepeatSections,
                          onChanged: (_) async {
                            await print.toggleRepeatSections();
                          },
                        ),
                        _buildFilterToggle(
                          context,
                          label: l10n.annotations,
                          value: s.showAnnotations,
                          onChanged: (_) async {
                            await print.toggleAnnotations();
                          },
                        ),
                        
                      ],
                    ),
                  ),
                ),
                SizedBox(),
              ],
            ),
          ),
        ),
      ),
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
