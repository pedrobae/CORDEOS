import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_rename_role.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleCard extends StatelessWidget {
  final int scheduleID;
  final int roleID; // Role or RoleDTO object

  const RoleCard({super.key, required this.scheduleID, required this.roleID});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Selector<LocalScheduleProvider, Role?>(
      selector: (context, localSch) =>
          localSch.getSchedule(scheduleID)?.roles[roleID],
      builder: (context, role, child) {
        if (role == null) {
          return Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            spacing: 8.0,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.name, style: textTheme.titleMedium),
                    Text(
                      role.users.isEmpty
                          ? AppLocalizations.of(context)!.noMembers
                          : AppLocalizations.of(
                              context,
                            )!.xMembers(role.users.length),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.surfaceContainerLowest,
                      ),
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              // ACTIONS
              FilledTextButton(
                text: AppLocalizations.of(context)!.assign,
                isDense: true,
                isDark: true,
                onPressed: () => _openAssignMemberSheet(context),
              ),
              FilledTextButton(
                text: AppLocalizations.of(context)!.editPlaceholder(''),
                isDense: true,
                onPressed: () => _openEditRoleSheet(context),
              ),
              FilledTextButton(
                text: AppLocalizations.of(context)!.delete,
                isDense: true,
                onPressed: () {
                  if (scheduleID is String) {
                    return; // Prevent deletion of cloud schedule roles
                  }
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return DeleteConfirmationSheet(
                        itemType: AppLocalizations.of(context)!.role,
                        onConfirm: () {
                          context.read<LocalScheduleProvider>().deleteRole(
                            scheduleID,
                            roleID,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAssignMemberSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: UsersBottomSheet(scheduleId: scheduleID, roleID: roleID),
        );
      },
    );
  }

  void _openEditRoleSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditRoleSheet(scheduleID: scheduleID, roleID: roleID),
        );
      },
    );
  }
}
