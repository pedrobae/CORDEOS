import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditRoleSheet extends StatefulWidget {
  final int scheduleID;
  final int roleID;

  const EditRoleSheet({
    super.key,
    required this.scheduleID,
    required this.roleID,
  });

  @override
  State<EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends State<EditRoleSheet> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localSch = context.read<LocalScheduleProvider>();

      final role = localSch
          .getSchedule(widget.scheduleID)
          ?.roles[widget.roleID];

      if (role != null) {
        _nameController.text = role.name;
      }
    });
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.roleID == -1
                    ? AppLocalizations.of(
                        context,
                      )!.createPlaceholder(AppLocalizations.of(context)!.role)
                    : AppLocalizations.of(
                        context,
                      )!.editPlaceholder(AppLocalizations.of(context)!.role),
                style: textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          // NAME FIELD
          LabeledTextField(
            label: AppLocalizations.of(context)!.name,
            controller: _nameController,
            hint: AppLocalizations.of(context)!.roleNameHint,
            onSubmitted: (_) {
              final localSch = context.read<LocalScheduleProvider>();
              _onSubmit(localSch);
            },
          ),
          // SUBMIT BUTTON
          FilledTextButton(
            text: widget.roleID == -1
                ? AppLocalizations.of(context)!.create
                : AppLocalizations.of(context)!.save,
            isDark: true,
            onPressed: () {
              final localSch = context.read<LocalScheduleProvider>();
              _onSubmit(localSch);
            },
          ),

          SizedBox(),
        ],
      ),
    );
  }

  void _onSubmit(LocalScheduleProvider localSch) {
    if (widget.roleID == -1) {
      // CREATE NEW ROLE
      localSch.addRoleToSchedule(widget.scheduleID, _nameController.text);
    } else {
      // UPDATE EXISTING ROLE
      localSch.updateRoleName(
        widget.scheduleID,
        widget.roleID,
        _nameController.text,
      );
    }
    Navigator.of(context).pop();
  }
}
