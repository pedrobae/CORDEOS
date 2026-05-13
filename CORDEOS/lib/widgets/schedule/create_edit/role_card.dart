import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/common/delete_confirmation.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_add_user.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_rename_role.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleCard extends StatelessWidget {
  final dynamic scheduleID;
  final Role role;
  final bool canEdit;

  const RoleCard({
    super.key,
    required this.scheduleID,
    required this.role,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        spacing: 8.0,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            spacing: 8.0,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(role.name, style: textTheme.titleMedium)],
                ),
              ),
              if (canEdit) ...[
                // ACTIONS
                GestureDetector(
                  onTap: () => _openAddUserSheet(context),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(Icons.add),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openEditRoleSheet(context),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(Icons.edit),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (scheduleID is String) {
                      return; // Prevent deletion of cloud schedule roles
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return DeleteConfirmationSheet(
                          itemType: l10n.role,
                          onConfirm: () {
                            context.read<LocalScheduleProvider>().deleteRole(
                              scheduleID,
                              role.id,
                            );
                          },
                        );
                      },
                    );
                  },
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(Icons.delete, color: colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
          if (role.users.isEmpty) ...[
            Text(
              l10n.noMembers,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.surfaceContainerLowest,
              ),
              softWrap: false,
            ),
          ] else ...[
            UsersList(scheduleId: scheduleID, role: role, canEdit: canEdit),
          ],
        ],
      ),
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
          child: EditRoleSheet(scheduleID: scheduleID, roleID: role.id),
        );
      },
    );
  }

  void _openAddUserSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddUserSheet(scheduleId: scheduleID, roleID: role.id),
        );
      },
    );
  }
}
