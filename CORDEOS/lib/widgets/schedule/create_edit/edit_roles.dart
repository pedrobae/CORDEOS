import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/create_edit/role_card.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_rename_role.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditRoles extends StatelessWidget {
  final dynamic scheduleId;
  final bool canEdit;

  const EditRoles({super.key, required this.scheduleId, this.canEdit = true});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ROLES LIST
          Expanded(
            child:
                Selector2<
                  LocalScheduleProvider,
                  CloudScheduleProvider,
                  List<Role>
                >(
                  selector: (context, localSch, cloudSch) {
                    final roles = <Role>[];
                    if (scheduleId is int)
                      roles.addAll(
                        localSch.getSchedule(scheduleId)!.roles.values,
                      );

                    if (scheduleId is String) {
                      int i = -1;
                      for (final roleDto
                          in cloudSch.getSchedule(scheduleId)!.roles) {
                        roles.add(roleDto.toDomain(i));
                        i--;
                      }
                    }
                    return roles;
                  },
                  builder: (context, roles, child) {
                    if (roles.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            Text(l10n.noRoles, style: textTheme.headlineSmall),
                            SizedBox(height: 16),
                            Text(
                              l10n.addRolesInstructions,
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: roles.length,
                      itemBuilder: (context, index) {
                        final role = roles[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: RoleCard(
                            scheduleID: scheduleId,
                            role: role,
                            canEdit: canEdit,
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
          // ADD ROLE BUTTON
          if (canEdit)
            FilledTextButton(
              text: l10n.role,
              isDense: true,
              icon: Icons.add,
              onPressed: () => showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: EditRoleSheet(scheduleID: scheduleId, roleID: -1),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
