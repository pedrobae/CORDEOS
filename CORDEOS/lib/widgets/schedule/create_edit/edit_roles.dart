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

  const EditRoles({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              AppLocalizations.of(
                context,
              )!.editPlaceholder(AppLocalizations.of(context)!.roles),
              style: textTheme.titleMedium,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.save, size: 30,),
                onPressed: () {
                  localSch.saveSchedule(scheduleId);
                  localSch.uploadChangesToCloud(scheduleId, auth.id!);
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
                      Text(
                        AppLocalizations.of(context)!.noRoles,
                        style: textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.addRolesInstructions,
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  children: schedule.roles.map((role) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: RoleCard(scheduleId: scheduleId, role: role),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        // ADD ROLE BUTTON
        FilledTextButton(
          text: AppLocalizations.of(context)!.role,
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
                child: EditRoleSheet(scheduleId: scheduleId, role: null),
              );
            },
          ),
        ),
      ],
    );
  }
}
