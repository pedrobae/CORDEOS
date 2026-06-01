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
  final ValueNotifier<bool> validFormNotifier;

  const EditDetails({
    super.key,
    required this.scheduleID,
    required this.validFormNotifier,
  });

  @override
  State<EditDetails> createState() => _EditDetailsState();
}

class _EditDetailsState extends State<EditDetails> {
  final _formKey = GlobalKey<FormState>();

  bool showDateError = false;
  bool showTimeError = false;

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final roomVenueController = TextEditingController();

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
      }
      _addListeners();
    });
  }

  void _notifyListeners(bool isValid) {
    if (widget.validFormNotifier.value != isValid) {
      widget.validFormNotifier.value = isValid;
    }
  }

  void _addListeners() {
    nameController.addListener(() {
      if (nameController.value.text.length != 0) {
        context.read<LocalScheduleProvider>().cacheName(
          widget.scheduleID,
          nameController.text,
        );
      }
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

  bool _scheduleIsValid(Schedule schedule) {
    return _formKey.currentState?.validate() == true &&
        schedule.date.compareTo(
              DateTime.fromMicrosecondsSinceEpoch(8.64e10.toInt()),
            ) >
            0;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();
    final auth = context.read<MyAuthProvider>();

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
            icon: Icon(Icons.save, size: 30),
            onPressed: () {
              final localSch = context.read<LocalScheduleProvider>();
              final schedule = localSch.getSchedule(widget.scheduleID);
              if (schedule == null) {
                debugPrint(
                  'EDIT DETAILS WIDGET - Schedule with ID ${widget.scheduleID} not found',
                );
                return;
              }
              if (_scheduleIsValid(schedule)) {
                localSch.saveDetails(widget.scheduleID);
                localSch.uploadChangesToCloud(widget.scheduleID, auth.id!);
                nav.pop();
              }
            },
          ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              LabeledTextField(
                label: l10n.requiredPlaceholder(l10n.scheduleName),
                controller: nameController,
                validator: (value) {
                  String? error;
                  if (value == null || value.trim().isEmpty) {
                    error = l10n.pleaseEnterScheduleName;
                  }
                  _notifyListeners(error == null);
                  return error;
                },
              ),
              _buildDatePickerField(label: l10n.requiredPlaceholder(l10n.date)),
              _buildTimePickerField(
                label: l10n.requiredPlaceholder(l10n.startTime),
              ),
              LabeledTextField(
                label: l10n.requiredPlaceholder(l10n.location),
                controller: locationController,
                validator: (value) {
                  String? error;
                  if (value == null || value.trim().isEmpty) {
                    error = l10n.pleaseEnterLocation;
                  }
                  _notifyListeners(error == null);
                  return error;
                },
              ),
              LabeledTextField(
                label: l10n.optionalPlaceholder(l10n.roomVenue),
                controller: roomVenueController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({required String label}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                    final date = localSch.getSchedule(widget.scheduleID)!.date;
                    if (date.compareTo(
                          DateTime.fromMicrosecondsSinceEpoch(8.64e10.toInt()),
                        ) <=
                        0)
                      return '';
                    return DateTimeUtils.formatDate(date);
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
        if (showDateError)
          Text(
            l10n.pleaseSelectDate,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
      ],
    );
  }

  VoidCallback _showDatePicker() {
    return () async {
      final localSch = context.read<LocalScheduleProvider>();

      final schedule = localSch.getSchedule(widget.scheduleID);

      final initialDate =
          (schedule != null &&
              schedule.date.compareTo(
                    DateTime.fromMicrosecondsSinceEpoch(8.64e10.toInt()),
                  ) >
                  0)
          ? schedule.date
          : null;
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
        setState(() {
          showDateError = false;
        });
      } else if (initialDate == null) {
        _notifyListeners(false);
        setState(() {
          showDateError = true;
        });
      }
    };
  }

  Widget _buildTimePickerField({required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

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
                    final date = localSch.getSchedule(widget.scheduleID)!.date;
                    if (date == DateTime.fromMicrosecondsSinceEpoch(0))
                      return '';
                    return DateTimeUtils.formatTime(date);
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
        if (showTimeError)
          Text(
            l10n.pleaseSelectTime,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
      ],
    );
  }

  VoidCallback _showTimePicker() {
    final localSch = context.read<LocalScheduleProvider>();
    final schedule = localSch.getSchedule(widget.scheduleID);

    return () async {
      final initialTime =
          (schedule != null &&
              schedule.date.compareTo(DateTime.fromMicrosecondsSinceEpoch(0)) >
                  0)
          ? schedule.date
          : null;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime != null
            ? TimeOfDay.fromDateTime(initialTime)
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

        setState(() {
          showTimeError = false;
        });
      } else if (initialTime == null) {
        _notifyListeners(false);
        setState(() {
          showTimeError = true;
        });
      }
    };
  }
}
