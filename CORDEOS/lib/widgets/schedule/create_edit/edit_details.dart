import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/utils/date_time_theme.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditDetails extends StatefulWidget {
  final int scheduleID;

  const EditDetails({super.key, required this.scheduleID});

  @override
  State<EditDetails> createState() => _EditDetailsState();
}

class _EditDetailsState extends State<EditDetails> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final roomVenueController = TextEditingController();
  final dateController = TextEditingController();
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();

    selectedTime = TimeOfDay.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localScheduleProvider = context.read<LocalScheduleProvider>();

      final schedule = localScheduleProvider.getSchedule(widget.scheduleID);

      if (schedule == null) {
        debugPrint('Schedule with ID ${widget.scheduleID} not found');

        return;
      } else {
        nameController.text = schedule.name;
        locationController.text = schedule.location;
        roomVenueController.text = schedule.roomVenue ?? '';
        dateController.text = DateTimeUtils.formatDate(schedule.date);
        selectedTime = schedule.time;
      }
      _addListeners();
    });
  }

  void _addListeners() {
    nameController.addListener(() {
      context.read<LocalScheduleProvider>().cacheName(
        widget.scheduleID,
        nameController.text,
      );
    });

    locationController.addListener(() {
      context.read<LocalScheduleProvider>().cacheLocation(
        widget.scheduleID,
        locationController.text,
      );
    });

    roomVenueController.addListener(() {
      context.read<LocalScheduleProvider>().cacheRoomVenue(
        widget.scheduleID,
        roomVenueController.text,
      );
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    roomVenueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();
    final auth = context.read<MyAuthProvider>();
    final localSch = context.read<LocalScheduleProvider>();

    if (widget.scheduleID == -1) {
      return _buildForm();
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => nav.attemptPop(context)),
        title: Text(
          AppLocalizations.of(context)!.info,
          style: textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            onPressed: () {
              localSch.saveSchedule(widget.scheduleID);
              localSch.uploadChangesToCloud(widget.scheduleID, auth.id!);
              nav.pop();
            },
            icon: Icon(Icons.save, size: 30,),
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: _buildForm()),
    );
  }

  Form _buildForm() {
    return Form(
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            LabeledTextField(
              label: AppLocalizations.of(context)!.scheduleName,
              controller: nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterScheduleName;
                }
                return null;
              },
            ),
            _buildDatePickerField(
              label: AppLocalizations.of(context)!.date,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterDate;
                }
                return null;
              },
            ),
            _buildTimePickerField(
              label: AppLocalizations.of(context)!.startTime,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterStartTime;
                }
                return null;
              },
            ),
            LabeledTextField(
              label: AppLocalizations.of(context)!.location,
              controller: locationController,
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
              controller: roomVenueController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    String? Function(String?)? validator,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(label, style: textTheme.labelLarge),
        TextFormField(
          validator: validator,
          controller: dateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: label,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(0),
            ),
            visualDensity: VisualDensity.compact,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: _showDatePicker(),
        ),
      ],
    );
  }

  VoidCallback _showDatePicker() {
    return () async {
      final localSch = context.read<LocalScheduleProvider>();

      final initialDate = dateController.text.isNotEmpty
          ? DateTimeUtils.parseDateTime(dateController.text)
          : DateTime.now();
      final firstDate = DateTime.now().subtract(const Duration(days: 365));
      final lastDate = DateTime.now().add(const Duration(days: 365));

      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );

      if (pickedDate != null) {
        localSch.cacheDate(widget.scheduleID, pickedDate);
        dateController.text = DateTimeUtils.formatDate(pickedDate);
      }
    };
  }

  Widget _buildTimePickerField({
    required String label,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        TextFormField(
          validator: validator,
          initialValue: DateTimeUtils.formatTime(
            DateTime(0, 0, 0, selectedTime.hour, selectedTime.minute),
          ),
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
            suffixIcon: Icon(Icons.access_time),
          ),
          onTap: _showTimePicker(),
        ),
      ],
    );
  }

  VoidCallback _showTimePicker() {
    final localSch = context.read<LocalScheduleProvider>();

    return () async {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: DateTimePickerTheme.timePickerTheme(context),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        localSch.cacheTime(widget.scheduleID, pickedTime);
        setState(() {
          selectedTime = pickedTime;
        });
      }
    };
  }
}
