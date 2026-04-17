import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/utils/timezone_utils.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LabeledTimezonePicker extends StatefulWidget {
  final String? timezone;
  final Function(String) onTimezoneChanged;

  const LabeledTimezonePicker({
    super.key,
    this.timezone,
    required this.onTimezoneChanged,
  });

  @override
  State<LabeledTimezonePicker> createState() => _LabeledTimezonePickerState();
}

class _LabeledTimezonePickerState extends State<LabeledTimezonePicker> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          AppLocalizations.of(context)!.timezone,
          style: textTheme.labelLarge,
        ),
        GestureDetector(
          onTap: () => showTimezoneSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.timezone?.isEmpty ?? true
                      ? AppLocalizations.of(context)!.timezoneHint
                      : widget.timezone!,
                  style: textTheme.bodyLarge?.copyWith(
                    color: widget.timezone?.isEmpty ?? true
                        ? colorScheme.shadow
                        : colorScheme.onSurface,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void showTimezoneSheet(BuildContext context) {
    context.read<NavigationProvider>().push(
      () => TimezoneSheet(
        timezone: widget.timezone,
        onTimezoneChanged: widget.onTimezoneChanged,
      ),
    );
  }
}

class TimezoneSheet extends StatefulWidget {
  final String? timezone;
  final Function(String) onTimezoneChanged;

  const TimezoneSheet({
    super.key,
    this.timezone,
    required this.onTimezoneChanged,
  });

  @override
  State<TimezoneSheet> createState() => _TimezoneSheetState();
}

class _TimezoneSheetState extends State<TimezoneSheet> {
  final filteredTimezones = <String>[];
  final TextEditingController _searchController = TextEditingController();
  late final List<String> _allTimezones;

  @override
  void initState() {
    super.initState();

    _allTimezones = TimezoneUtils.getAllTimezones();
    filteredTimezones.addAll(_allTimezones);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.shadow, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.chooseTimezone,
                  style: textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () =>
                      context.read<NavigationProvider>().attemptPop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // TIMEZONE OPTIONS
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: colorScheme.shadow, width: 1),
                ),
                borderRadius: BorderRadius.circular(0),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shrinkWrap: true,
                itemCount: filteredTimezones.length,
                itemBuilder: (context, index) {
                  final timezone = filteredTimezones[index];
                  bool isSelected = timezone == widget.timezone;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledTextButton(
                      text: timezone,
                      isDark: isSelected,
                      trailingIcon: Icons.chevron_right,
                      onPressed: () {
                        widget.onTimezoneChanged(timezone);
                        context.read<NavigationProvider>().pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchTimezone,
                prefixIcon: const Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide(color: colorScheme.shadow, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: colorScheme.shadow, width: 2),
                ),
                visualDensity: VisualDensity.compact,
              ),
              onChanged: (value) {
                setState(() {
                  filteredTimezones.clear();
                  filteredTimezones.addAll(
                    _allTimezones.where(
                      (tz) => tz.toLowerCase().contains(value.toLowerCase()),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
