import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class DurationPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final bool isEnabled;

  const DurationPickerField({
    super.key,
    required this.controller,
    this.label,
    this.isEnabled = true,
  });

  @override
  State<DurationPickerField> createState() => _DurationPickerFieldState();
}

class _DurationPickerFieldState extends State<DurationPickerField> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    final duration = DateTimeUtils.parseDuration(widget.controller.text);
    _minutes = duration.inMinutes;
    _seconds = duration.inSeconds % 60;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (widget.label != null)
          Text(widget.label!, style: textTheme.labelMedium),
        GestureDetector(
          onTap: () {
            if (widget.isEnabled) _openDurationPicker(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              spacing: 8,
              children: [
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, child) {
                    return Expanded(
                      child: Text(
                        widget.controller.text.isEmpty
                            ? AppLocalizations.of(context)!.durationHint
                            : widget.controller.text,
                        style: TextStyle(
                          color: widget.controller.text.isEmpty
                              ? colorScheme.shadow
                              : colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                Icon(Icons.access_time, color: colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openDurationPicker(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.setPlaceholder(
                          AppLocalizations.of(context)!.duration,
                        ),
                        style: textTheme.titleMedium,
                      ),
                      CloseButton(onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pluralPlaceholder(
                              AppLocalizations.of(context)!.minute,
                            ),
                            style: textTheme.labelMedium,
                          ),
                          NumberPicker(
                            value: _minutes,
                            infiniteLoop: true,
                            itemCount: 4,
                            minValue: 0,
                            maxValue: 59,
                            textStyle: textTheme.labelLarge?.copyWith(
                              color: colorScheme.surfaceContainerLowest,
                            ),
                            selectedTextStyle: textTheme.headlineSmall
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                            onChanged: (value) {
                              setModalState(() => _minutes = value);
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pluralPlaceholder(
                              AppLocalizations.of(context)!.second,
                            ),
                            style: textTheme.labelMedium,
                          ),
                          NumberPicker(
                            value: _seconds,
                            infiniteLoop: true,
                            itemCount: 4,
                            minValue: 0,
                            maxValue: 59,
                            textStyle: textTheme.labelLarge?.copyWith(
                              color: colorScheme.surfaceContainerLowest,
                            ),
                            selectedTextStyle: textTheme.headlineSmall
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                            onChanged: (value) {
                              setModalState(() => _seconds = value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.save,
                    isDark: true,
                    onPressed: () {
                      final duration = Duration(
                        minutes: _minutes,
                        seconds: _seconds,
                      );

                      widget.controller.text = DateTimeUtils.formatDuration(
                        duration,
                      );

                      Navigator.of(context).pop(duration);
                    },
                  ),
                  SizedBox(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
