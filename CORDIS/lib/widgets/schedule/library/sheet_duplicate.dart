import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/helpers/codes.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:flutter/material.dart';

import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/settings/settings_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';

import 'package:cordis/services/sync_service.dart';

import 'package:cordis/utils/date_time_theme.dart';
import 'package:cordis/utils/timezone_utils.dart';

import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';

class DuplicateScheduleSheet extends StatefulWidget {
  final dynamic scheduleId;

  const DuplicateScheduleSheet({super.key, required this.scheduleId});

  @override
  State<DuplicateScheduleSheet> createState() => _DuplicateScheduleSheetState();
}

class _DuplicateScheduleSheetState extends State<DuplicateScheduleSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController roomVenueController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If editing an existing schedule, load its details
    if (widget.scheduleId != null) {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final cloudScheduleProvider = context.read<CloudScheduleProvider>();

      if (widget.scheduleId is int) {
        final schedule = localScheduleProvider.getSchedule(widget.scheduleId)!;
        nameController.text = '${schedule.name} ${AppLocalizations.of(context)!.copySuffix}';
        dateController.text = DateTimeUtils.formatDate(schedule.date);
        startTimeController.text = DateTimeUtils.formatTime(
          DateTime(schedule.time.hour, schedule.time.minute),
        );
        locationController.text = schedule.location;
      } else {
        final schedule = cloudScheduleProvider.getSchedule(widget.scheduleId)!;
        nameController.text = '${schedule.name} ${AppLocalizations.of(context)!.copySuffix}';
        dateController.text = DateTimeUtils.formatDate(
          schedule.datetime.toDate(),
        );
        startTimeController.text = DateTimeUtils.formatTime(
          schedule.datetime.toDate(),
        );
        locationController.text = schedule.location;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    locationController.dispose();
    roomVenueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.duplicatePlaceholder(
                    AppLocalizations.of(context)!.schedule,
                  ),
                  style: textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // FORM
            Form(
              autovalidateMode: AutovalidateMode.onUnfocus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  LabeledTextField(
                    label: AppLocalizations.of(context)!.scheduleName,
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterScheduleName;
                      }
                      return null;
                    },
                  ),
                  _buildDatePickerField(
                    context,
                    label: AppLocalizations.of(context)!.date,
                    controller: dateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterDate;
                      }
                      return null;
                    },
                  ),
                  _buildTimePickerField(
                    context,
                    label: AppLocalizations.of(context)!.startTime,
                    controller: startTimeController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterStartTime;
                      }
                      return null;
                    },
                  ),
                  LabeledTextField(
                    label: AppLocalizations.of(context)!.location,
                    controller: locationController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterLocation;
                      }
                      return null;
                    },
                  ),
                  LabeledTextField(
                    label: AppLocalizations.of(context)!.optionalPlaceholder(
                      AppLocalizations.of(context)!.roomVenue,
                    ),
                    controller: roomVenueController,
                  ),
                ],
              ),
            ),

            // ACTIONS
            // confirm
            FilledTextButton(
              text: AppLocalizations.of(context)!.keepGoing,
              isDark: true,
              onPressed: () => _duplicate(context),
            ),

            // cancel
            FilledTextButton(
              text: AppLocalizations.of(context)!.cancel,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _duplicate(BuildContext context) async {
    final localSch = context.read<LocalScheduleProvider>();
    final cloudSch = context.read<CloudScheduleProvider>();
    final auth = context.read<MyAuthProvider>();
    final sync = ScheduleSyncService();

    Navigator.of(context).pop();
    Navigator.of(context).pop();

    if (widget.scheduleId is int) {
      localSch.duplicateSchedule(
        widget.scheduleId,
        nameController.text,
        dateController.text,
        startTimeController.text,
        locationController.text,
        roomVenueController.text,
      );
    } else {
      final scheduleDto = cloudSch.getSchedule(widget.scheduleId)!;

      cloudSch.startSyncing(widget.scheduleId);
      final scheduleID = await sync.scheduleToLocal(
        scheduleDto.copyWith(
          ownerFirebaseId: auth.id!,
          roles: [],
          datetime: Timestamp.fromDate(
            DateTimeUtils.parseDateTime(dateController.text)!,
          ),
          firebaseId: '',
          location: locationController.text,
          name: nameController.text,
          roomVenue: roomVenueController.text,
          shareCode: generateShareCode(),
        ),
      );
      localSch.loadSchedule(scheduleID);
      cloudSch.stopSyncing(widget.scheduleId);
    }
  }
}

Widget _buildDatePickerField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      TextFormField(
        validator: validator,
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: label,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          visualDensity: VisualDensity.compact,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context, controller),
          ),
        ),
        onTap: () => _selectDate(context, controller),
      ),
    ],
  );
}

Widget _buildTimePickerField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      TextFormField(
        validator: validator,
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: label,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          visualDensity: VisualDensity.compact,
          suffixIcon: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () => _selectTime(context, controller),
          ),
        ),
        onTap: () => _selectTime(context, controller),
      ),
    ],
  );
}

Future<void> _selectDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final settingsProvider = context.read<SettingsProvider>();

  // Get current time in user's timezone
  final tzNow = TimezoneUtils.now(settingsProvider.timeZone);
  DateTime initialDate = tzNow;

  // Parse existing date if available
  if (controller.text.isNotEmpty) {
    try {
      final parts = controller.text.split('/');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {
      // If parsing fails, use current date
      initialDate = tzNow;
    }
  }

  final selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDate.isAfter(DateTime(2020)) ? initialDate : tzNow,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DateTimePickerTheme.datePickerTheme(context),
        ),
        child: child!,
      );
    },
  );

  if (selectedDate != null) {
    controller.text =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
  }
}

Future<void> _selectTime(
  BuildContext context,
  TextEditingController controller,
) async {
  TimeOfDay initialTime = TimeOfDay.now();

  // Parse existing time if available
  if (controller.text.isNotEmpty) {
    try {
      final parts = controller.text.split(':');
      if (parts.length == 2) {
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {
      // If parsing fails, use current time
    }
  }

  final selectedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: DateTimePickerTheme.timePickerTheme(context),
        ),
        child: child!,
      );
    },
  );

  if (selectedTime != null) {
    final hours = selectedTime.hour.toString();
    final minutes = selectedTime.minute.toString().padLeft(2, '0');
    controller.text = '$hours:$minutes';
  }
}
