import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:cordis/utils/date_time_theme.dart';
import 'package:cordis/utils/timezone_utils.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleForm extends StatefulWidget {
  final dynamic scheduleId;
  final TextEditingController nameController;
  final TextEditingController dateController;
  final TextEditingController startTimeController;
  final TextEditingController locationController;
  final TextEditingController roomVenueController;

  const ScheduleForm({
    super.key,
    this.scheduleId,
    required this.nameController,
    required this.dateController,
    required this.startTimeController,
    required this.locationController,
    required this.roomVenueController,
  });

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If editing an existing schedule, load its details
    if (widget.scheduleId != null) {
      final localScheduleProvider = context.read<LocalScheduleProvider>();
      final cloudScheduleProvider = context.read<CloudScheduleProvider>();

      if (widget.scheduleId is int) {
        final schedule = localScheduleProvider.getSchedule(widget.scheduleId)!;
        widget.nameController.text = schedule.name;
        widget.dateController.text =
            '${schedule.date.day}/${schedule.date.month}/${schedule.date.year}';
        widget.startTimeController.text =
            '${schedule.time.hour}:${schedule.time.minute.toString().padLeft(2, '0')}';
        widget.locationController.text = schedule.location;
      } else {
        final schedule = cloudScheduleProvider.getSchedule(widget.scheduleId)!;
        widget.nameController.text = schedule.name;
        widget.dateController.text =
            '${schedule.datetime.toDate().day}/${schedule.datetime.toDate().month}/${schedule.datetime.toDate().year}';
        widget.startTimeController.text =
            '${schedule.datetime.toDate().hour}:${schedule.datetime.toDate().minute.toString().padLeft(2, '0')}';
        widget.locationController.text = schedule.location;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            LabeledTextField(
              label: AppLocalizations.of(context)!.scheduleName,
              controller: widget.nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterScheduleName;
                }
                return null;
              },
            ),
            _buildDatePickerField(
              label: AppLocalizations.of(context)!.date,
              controller: widget.dateController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterDate;
                }
                return null;
              },
            ),
            _buildTimePickerField(
              AppLocalizations.of(context)!.startTime,
              widget.startTimeController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterStartTime;
                }
                return null;
              },
            ),
            LabeledTextField(
              label: AppLocalizations.of(context)!.location,
              controller: widget.locationController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterLocation;
                }
                return null;
              },
            ),
            LabeledTextField(
              label: AppLocalizations.of(
                context,
              )!.optionalPlaceholder(AppLocalizations.of(context)!.roomVenue),
              controller: widget.roomVenueController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
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
    String label,
    TextEditingController controller, {
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
}
