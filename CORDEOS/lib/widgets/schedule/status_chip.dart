import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/schedule.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final ScheduleState status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: switch (status) {
          ScheduleState.completed => colorScheme.onSurface,
          ScheduleState.draft => Color.fromARGB(255, 226, 147, 0),
          ScheduleState.published => Color.fromARGB(255, 66, 180, 62),
        },
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        switch (status) {
          ScheduleState.completed => AppLocalizations.of(context)!.completed,
          ScheduleState.draft => AppLocalizations.of(context)!.draft,
          ScheduleState.published => AppLocalizations.of(context)!.published,
        },
        style: textTheme.bodyMedium!.copyWith(
          color: switch (status) {
            ScheduleState.completed => colorScheme.surface,
            ScheduleState.draft => colorScheme.onSurface,
            ScheduleState.published => colorScheme.surface,
          },
          fontSize: 13,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
