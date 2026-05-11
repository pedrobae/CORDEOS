import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LayoutSetting {
  columns,
  margin,
  internalGaps,
  verticalSpacing,
  letterSpacing,
}

class PrintLayout extends StatefulWidget {
  const PrintLayout({super.key});

  @override
  State<PrintLayout> createState() => _PrintLayoutState();
}

class _PrintLayoutState extends State<PrintLayout> {
  Widget? _openSetting;
  LayoutSetting? _activeSetting;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final print = context.read<PrintingProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Selector<PrintingProvider, bool>(
                selector: (context, print) => print.columnCount == 2,
                builder: (context, hasColumns, child) {
                  return IconButton(
                    onPressed: () async => await print.toggleColumnCount(),
                    icon: Icon(
                      Icons.view_column,
                      color: hasColumns ? colorScheme.primary : null,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: _toggleSlider(LayoutSetting.verticalSpacing),
                icon: Icon(Icons.vertical_distribute),
                color: _activeSetting == LayoutSetting.verticalSpacing
                    ? colorScheme.primary
                    : null,
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: _toggleSlider(LayoutSetting.letterSpacing),
                icon: Icon(Icons.space_bar_outlined),
                color: _activeSetting == LayoutSetting.letterSpacing
                    ? colorScheme.primary
                    : null,
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: _toggleSlider(LayoutSetting.margin),
                icon: Icon(Icons.margin),
                color: _activeSetting == LayoutSetting.margin
                    ? colorScheme.primary
                    : null,
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: _toggleSlider(LayoutSetting.internalGaps),
                icon: Icon(
                  Icons.space_dashboard,
                  color: _activeSetting == LayoutSetting.internalGaps
                      ? colorScheme.primary
                      : null,
                ),
              ),
            ),
          ],
        ),
        if (_openSetting != null) _openSetting!,
      ],
    );
  }

  VoidCallback _toggleSlider(LayoutSetting setting) {
    return () {
      if (_activeSetting == setting) {
        setState(() {
          _activeSetting = null;
          _openSetting = null;
        });
      } else {
        setState(() {
          _activeSetting = setting;
          _openSetting = _buildSlider(setting);
        });
      }
    };
  }

  Widget _buildSlider(LayoutSetting setting) {
    final l10n = AppLocalizations.of(context)!;

    final print = context.read<PrintingProvider>();

    switch (setting) {
      case LayoutSetting.columns:
        throw Exception('Columns are not a slider');
      case LayoutSetting.margin:
        return Selector<PrintingProvider, double>(
          selector: (context, print) => print.margin.clamp(5, 50),
          builder: (context, margin, child) => _buildContainer(
            value: print.margin,
            label: l10n.margin,
            minValue: 5,
            maxValue: 50,
            onChanged: (v) async {
              await print.setMargin(v);
            },
          ),
        );
      case LayoutSetting.internalGaps:
        return Selector<PrintingProvider, double>(
          selector: (context, print) => print.internalGap.clamp(0, 40),
          builder: (context, internalGap, child) => _buildContainer(
            value: print.internalGap,
            label: l10n.internalGap,
            minValue: 0,
            maxValue: 40,
            onChanged: (v) async {
              await print.setInternalGap(v);
            },
          ),
        );
      case LayoutSetting.verticalSpacing:
        return Selector<PrintingProvider, double>(
          selector: (context, print) => print.heightSpacing.clamp(-0.1, 0.2),
          builder: (context, heightSpacingMult, child) => _buildContainer(
            value: heightSpacingMult * 100,
            label: l10n.heightSpacing,
            minValue: -10,
            maxValue: 20,
            onChanged: (v) async {
              await print.setHeightSpacingMult((v / 100).clamp(-0.1, 0.2));
            },
          ),
        );
      case LayoutSetting.letterSpacing:
        return Selector<PrintingProvider, double>(
          selector: (context, print) => print.letterSpacing.clamp(-3, 3),
          builder: (context, letterSpacing, child) => _buildContainer(
            value: print.letterSpacing,
            label: l10n.letterSpacing,
            minValue: -3,
            maxValue: 3,
            onChanged: (v) async {
              await print.setLetterSpacing(v);
            },
          ),
        );
    }
  }

  Container _buildContainer({
    required double value,
    required String label,
    required double minValue,
    required double maxValue,
    required void Function(double) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: colorScheme.surfaceContainerLowest, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.labelLarge)),
          Text(
            value.toStringAsFixed(1),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 150,
            child: Slider(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              value: value,
              divisions: 100,
              min: minValue,
              max: maxValue,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
