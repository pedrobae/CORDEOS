import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class UsersList extends StatelessWidget {
  final int scheduleId;
  final int roleID;
  final bool canEdit;

  const UsersList({
    super.key,
    required this.scheduleId,
    required this.roleID,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Selector<LocalScheduleProvider, ({String? name, int memberCount})>(
      selector: (context, localSch) {
        final role = localSch.getSchedule(scheduleId)!.roles[roleID];

        return (name: role?.name, memberCount: role?.users.length ?? 0);
      },
      builder: (context, s, child) {
        if (s.name == null) {
          return Center(child: Text(l10n.error));
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < s.memberCount; i++) ...[
              Divider(color: colorScheme.surfaceContainerLowest, height: 1),
              _buildMemberCard(context, i),
            ],
            if (canEdit)
              FilledTextButton(
                text: l10n.clear,
                isDense: true,
                isDark: true,
                onPressed: () {
                  context.read<LocalScheduleProvider>().clearUsersFromRole(
                    scheduleId,
                    roleID,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Selector<LocalScheduleProvider, User?>(
      selector: (context, localSch) {
        final schedule = localSch.getSchedule(scheduleId);
        return schedule?.roles[roleID]?.users[index];
      },
      builder: (context, member, child) {
        if (member == null) {
          return Center(child: Text(AppLocalizations.of(context)!.error));
        }
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.username, style: textTheme.titleSmall),
                  Text(member.email, style: textTheme.bodySmall),
                ],
              ),
            ),
            if (canEdit)
              IconButton(
                onPressed: () {
                  final localSch = context.read<LocalScheduleProvider>();

                  localSch.removeUserFromRole(scheduleId, roleID, member.id!);
                },
                icon: Icon(Icons.remove_circle_outline),
                color: colorScheme.error,
              ),
          ],
        );
      },
    );
  }
}
