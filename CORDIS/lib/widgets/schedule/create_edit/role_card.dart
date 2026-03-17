import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/common/delete_confirmation.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/schedule/create_edit/sheet_rename_role.dart';
import 'package:cordis/widgets/schedule/create_edit/sheet_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleCard extends StatelessWidget {
  final dynamic scheduleId;
  final dynamic role; // Role or RoleDTO object

  const RoleCard({super.key, required this.scheduleId, required this.role});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<LocalScheduleProvider>(
      builder: (context, scheduleProvider, child) => SizedBox(
        width: double.infinity,
        child: Container(
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
              SizedBox(
                width: 60,
                child: FilledTextButton(
                  text: AppLocalizations.of(context)!.assign,
                  isDense: true,
                  isDark: true,
                  onPressed: () => _openAssignMemberSheet(context, role),
                ),
              ),
              SizedBox(
                width: 60,
                child: FilledTextButton(
                  text: AppLocalizations.of(context)!.editPlaceholder(''),
                  isDense: true,
                  onPressed: () => _openEditRoleSheet(context, role),
                ),
              ),
              SizedBox(
                width: 60,
                child: FilledTextButton(
                  text: AppLocalizations.of(context)!.delete,
                  isDense: true,
                  onPressed: () {
                    if (scheduleId is String) {
                      return; // Prevent deletion of cloud schedule roles
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return DeleteConfirmationSheet(
                          itemType: AppLocalizations.of(context)!.role,
                          onConfirm: () {
                            scheduleProvider.deleteRole(
                              scheduleId,
                              role.id,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAssignMemberSheet(BuildContext context, dynamic role) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: UsersBottomSheet(scheduleId: scheduleId, role: role),
        );
      },
    );
  }

  void _openEditRoleSheet(BuildContext context, dynamic role) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditRoleSheet(scheduleId: scheduleId, role: role),
        );
      },
    );
  }
}
