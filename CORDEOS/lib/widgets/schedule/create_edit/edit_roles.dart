import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/user/my_auth_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/schedule/create_edit/role_card.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_rename_role.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditRoles extends StatelessWidget {
  final int scheduleId;
  final bool canEdit;

  const EditRoles({super.key, required this.scheduleId, this.canEdit = true});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final nav = context.read<NavigationProvider>();
    final auth = context.read<MyAuthProvider>();

    return Consumer<LocalScheduleProvider>(
      builder: (context, localSch, child) {
        if (scheduleId == -1) {
          return _buildContent(context, localSch);
        }

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => nav.attemptPop(context)),
            title: Text(
              l10n.editPlaceholder(l10n.roles),
              style: textTheme.titleMedium,
            ),
            actions: [
              if (canEdit)
                IconButton(
                  icon: Icon(Icons.save, size: 30),
                  onPressed: () async {
                    await localSch.saveUserRoles(scheduleId);
                    await localSch.uploadChangesToCloud(scheduleId, auth.id!);
                    nav.pop();
                  },
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(context, localSch),
          ),
        );
      },
    );
  }

  Column _buildContent(BuildContext context, LocalScheduleProvider localSch) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ROLES LIST
        Expanded(
          child: Builder(
            builder: (context) {
              final schedule = localSch.getSchedule(scheduleId);

              if (schedule == null) {
                return Center(child: CircularProgressIndicator());
              }
              if (schedule.roles.isEmpty) {
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
              return SingleChildScrollView(
                child: Column(
                  children: schedule.roles.keys.map((roleID) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: RoleCard(
                        scheduleID: scheduleId,
                        roleID: roleID,
                        canEdit: canEdit,
                      ),
                    );
                  }).toList(),
                ),
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
    );
  }
}
