import 'package:cordis/helpers/chords/chords.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectKeySheet extends StatefulWidget {
  final bool selectingOriginalKey;
  final bool needsSave;

  const SelectKeySheet({super.key, this.needsSave = true, this.selectingOriginalKey = false});

  @override
  State<SelectKeySheet> createState() => _SelectKeySheetState();
}

class _SelectKeySheetState extends State<SelectKeySheet> {
  String? selectedKey;

  @override
  void initState() {
    super.initState();
    final tp = context.read<TranspositionProvider>();
    selectedKey = widget.selectingOriginalKey ? tp.originalKey : tp.transposedKey;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<TranspositionProvider>(
      builder: (context, tp, child) {
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
              Expanded(
                child: GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: ChordHelper.keyList.map((key) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (widget.needsSave) {
                            if (selectedKey == key) {
                              selectedKey = null;
                            } else {
                              selectedKey = key;
                            }
                          } else {
                            if (widget.selectingOriginalKey) {
                              tp.setOriginalKey(key);
                            } else {
                              tp.setTransposedKey(key);
                            }
                            Navigator.of(context).pop();
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
                ),
              ),
              FilledTextButton(
                text: AppLocalizations.of(context)!.originalKey,
                isDark: true,
                onPressed: () {
                  tp.setTransposedKey(null);
                  Navigator.of(context).pop();
                },
              ),
              if (widget.needsSave) ...[
                FilledTextButton(
                  text: AppLocalizations.of(context)!.save,
                  isDark: true,
                  onPressed: () {
                    tp.setTransposedKey(selectedKey);
                    Navigator.of(context).pop();
                  },
                ),
              ],

              SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
