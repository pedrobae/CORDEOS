import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StyleSettings extends StatelessWidget {
  const StyleSettings({super.key});

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
                    AppLocalizations.of(context)!.styleSettings,
                    style: textTheme.titleMedium,
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // SCROLL DIRECTION SETTINGS
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.scrollDirection,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    Switch(
                      value: settings.scrollDirection == Axis.vertical,
                      onChanged: (_) {
                        settings.toggleAxisDirection();
                      },
                      thumbIcon: WidgetStatePropertyAll(
                        settings.scrollDirection == Axis.vertical
                            ? const Icon(Icons.swap_vert)
                            : const Icon(Icons.swap_horiz),
                      ),
                      inactiveThumbColor: colorScheme.primary,
                      activeThumbColor: colorScheme.surfaceContainerLow,
                    ),
                  ],
                ),
              ),
              // FONT SETTINGS
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: settings.fontFamily,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'OpenSans',
                            child: Text(
                              'OpenSans',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Asimovian',
                            child: Text(
                              'Asimovian',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'Asimovian',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Atkinson',
                            child: Text(
                              'Atkinson',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'Atkinson',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Caveat',
                            child: Text(
                              'Caveat',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'Caveat',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) settings.setFontFamily(v);
                        },
                        underline: Container(),
                      ),
                    ),
                    const SizedBox(width: 32),
                    DropdownButton<double>(
                      value: settings.fontSize,
                      items: List.generate(12, (i) {
                        final double size = 12 + i * 2;
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size.toString()),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) settings.setFontSize(v);
                      },
                      underline: Container(),
                    ),
                  ],
                ),
              ),

              /// COMPACT VIEW
              _buildOption(
                context,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.compactView,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    Switch(
                      value: !settings.showSectionHeaders,
                      onChanged: (_) => settings.toggleSectionHeaders(),
                    ),
                  ],
                ),
              ),
              SizedBox(),
            ],
          ),
        );
      },
    );
  }

  Container _buildOption(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: colorScheme.surfaceContainerLowest, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}
