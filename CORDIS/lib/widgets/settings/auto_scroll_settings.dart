import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AutoScrollSettings extends StatelessWidget {
  const AutoScrollSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<LayoutSettingsProvider>(
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
                    AppLocalizations.of(context)!.autoScrollSettings,
                    style: textTheme.titleMedium,
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
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
                    value: settings.autoScrollEnabled,
                    onChanged: (value) {
                      settings.toggleAutoScroll();
                    },
                  ),
                ],
              ),
              // speed
              Column(
                children: [
                  Text(AppLocalizations.of(context)!.autoScrollSpeed),
                  Slider(
                    value: settings.autoScrollSpeed,
                    onChanged: (value) {
                      settings.setAutoScrollSpeed(value);
                    },
                    min: 0.5,
                    max: 1.5,
                    divisions: 8,
                    label: settings.autoScrollSpeed < 0.85
                        ? AppLocalizations.of(context)!.slow
                        : settings.autoScrollSpeed < 1.15
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
