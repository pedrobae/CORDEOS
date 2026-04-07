import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/providers/playlist/auto_scroll_provider.dart';
import 'package:cordeos/providers/playlist/play_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AutoScrollSettings extends StatefulWidget {
  const AutoScrollSettings({super.key});

  @override
  State<AutoScrollSettings> createState() => _AutoScrollSettingsState();
}

class _AutoScrollSettingsState extends State<AutoScrollSettings> {
  double? _localScrollSpeed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final scroll = context.read<ScrollProvider>();
    final state = context.read<PlayStateProvider>();

    return Selector<
      ScrollProvider,
      ({bool transparentButtons, bool scrollModeEnabled, double scrollSpeed})
    >(
      selector: (_, p) => (
        transparentButtons: p.transparentButtons,
        scrollModeEnabled: p.scrollModeEnabled,
        scrollSpeed: p.scrollSpeed,
      ),
      builder: (context, s, child) {
        _localScrollSpeed ??= s.scrollSpeed;
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
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.scrollSettings,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // TRANSPARENT BUTTONS
              // toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.transparentScrollButtons),
                  Switch(
                    trackOutlineColor: WidgetStateColor.fromMap({
                      WidgetState.selected: colorScheme.primary,
                      WidgetState.any: colorScheme.shadow,
                    }),
                    value: s.transparentButtons,
                    onChanged: (value) {
                      scroll.toggleTransparentButtons();
                      state.showButtonsTemporarily();
                    },
                  ),
                ],
              ),

              // AUTO SCROLL SETTINGS
              // toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.autoScroll),
                  Switch(
                    trackOutlineColor: WidgetStateColor.fromMap({
                      WidgetState.selected: colorScheme.primary,
                      WidgetState.any: colorScheme.shadow,
                    }),
                    value: scroll.scrollModeEnabled,
                    onChanged: (value) {
                      scroll.toggleAutoScrollMode();
                    },
                  ),
                ],
              ),
              // speed
              Column(
                children: [
                  Text(AppLocalizations.of(context)!.autoScrollSpeed),
                  Slider(
                    value: _localScrollSpeed!,
                    onChanged: (value) {
                      setState(() => _localScrollSpeed = value);
                    },
                    onChangeEnd: (value) {
                      scroll.setScrollSpeed(value);
                    },
                    min: 0.5,
                    max: 1.5,
                    divisions: 8,
                    label: _localScrollSpeed! < 0.85
                        ? AppLocalizations.of(context)!.slow
                        : _localScrollSpeed! < 1.15
                        ? AppLocalizations.of(context)!.normal
                        : AppLocalizations.of(context)!.fast,
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
