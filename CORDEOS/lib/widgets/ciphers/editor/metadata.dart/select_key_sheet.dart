import 'package:cordeos/helpers/chords/chords.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';

class SelectKeySheet extends StatefulWidget {
  final bool showSave;
  final bool showOriginal;
  final String? initialKey;
  final String originalKey;
  final Function(String) onKeySelected;
  final Function(String)? onSave;

  const SelectKeySheet({
    super.key,
    this.showSave = true,
    this.showOriginal = true,
    this.initialKey,
    required this.originalKey,
    required this.onKeySelected,
    this.onSave,
  });

  @override
  State<SelectKeySheet> createState() => _SelectKeySheetState();
}

class _SelectKeySheetState extends State<SelectKeySheet> {
  late String selectedKey;

  @override
  void initState() {
    super.initState();
    selectedKey = widget.initialKey ?? widget.originalKey;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: colorScheme.surface,
      ),
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
                AppLocalizations.of(context)!.keyHint,
                style: textTheme.titleMedium,
              ),
              CloseButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 8.0;

              final itemWidth = (constraints.maxWidth - (3 * spacing)) / 4;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: ChordHelper.keyList.map((key) {
                  return GestureDetector(
                    onTap: () {
                      if (selectedKey == key) {
                        widget.onKeySelected(widget.originalKey);
                      } else {
                        widget.onKeySelected(key);
                      }
                      setState(() {
                        if (selectedKey == key) {
                          selectedKey = widget.originalKey;
                        } else {
                          selectedKey = key;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: key == selectedKey
                            ? colorScheme.onSurface
                            : colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.onSurface,
                          width: 1,
                        ),
                      ),
                      width: itemWidth,
                      height: itemWidth / 2,
                      child: Center(
                        child: Text(
                          key,
                          style: textTheme.titleMedium?.copyWith(
                            color: key == selectedKey
                                ? colorScheme.surface
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (widget.showOriginal && widget.originalKey != '')
            FilledTextButton(
              text: AppLocalizations.of(context)!.originalKey,
              isDark: true,
              onPressed: () {
                widget.onKeySelected(widget.originalKey);
                Navigator.of(context).pop();
              },
            ),
          if (widget.showSave) ...[
            FilledTextButton(
              text: AppLocalizations.of(context)!.save,
              isDark: true,
              onPressed: () {
                if (widget.onSave != null) {
                  widget.onSave!(selectedKey);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
          SizedBox(),
        ],
      ),
    );
  }
}
