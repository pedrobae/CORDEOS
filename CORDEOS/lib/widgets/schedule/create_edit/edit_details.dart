import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/schedule.dart';
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

  @override
  void initState() {
    super.initState();

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

  bool _scheduleIsValid(Schedule? schedule) {
    return schedule != null &&
        schedule.name.isNotEmpty &&
        schedule.location.isNotEmpty;
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
              // validate details
              final schedule = localSch.getSchedule(widget.scheduleID);

              if (_scheduleIsValid(schedule)) {
                localSch.saveDetails(widget.scheduleID);
                localSch.uploadChangesToCloud(widget.scheduleID, auth.id!);
                nav.pop();
              } else {
                // feedback to user about missing fields
                if (schedule == null) return;

                if (schedule.name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.pleaseEnterScheduleName,
                      ),
                    ),
                  );
                }
                if (schedule.location.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.pleaseEnterLocation,
                      ),
                    ),
                  );
                }
              }
            },
            icon: Icon(Icons.save, size: 30),
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
        Text(label, style: textTheme.labelMedium),
        GestureDetector(
          onTap: _showDatePicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Selector<LocalScheduleProvider, String>(
                  selector: (context, localSch) {
                    final date = localSch.getSchedule(widget.scheduleID)?.date;
                    return date != null
                        ? DateTimeUtils.formatDate(date)
                        : DateTimeUtils.formatDate(DateTime.now());
                  },
                  builder: (context, formattedTime, child) {
                    return Text(formattedTime, style: textTheme.bodyLarge);
                  },
                ),
                Icon(Icons.calendar_today, color: colorScheme.primary),
              ],
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(label, style: textTheme.labelMedium),
        GestureDetector(
          onTap: _showTimePicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Selector<LocalScheduleProvider, String>(
                  selector: (context, localSch) {
                    final date = localSch.getSchedule(widget.scheduleID)?.date;
                    return date != null
                        ? DateTimeUtils.formatTime(date)
                        : DateTimeUtils.formatTime(DateTime.now());
                  },
                  builder: (context, formattedTime, child) {
                    return Text(formattedTime, style: textTheme.bodyLarge);
                  },
                ),
                Icon(Icons.access_time, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  VoidCallback _showTimePicker() {
    final localSch = context.read<LocalScheduleProvider>();

    return () async {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: localSch.getSchedule(widget.scheduleID)?.date != null
            ? TimeOfDay.fromDateTime(
                localSch.getSchedule(widget.scheduleID)!.date,
              )
            : TimeOfDay.now(),
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
      }
    };
  }
}
