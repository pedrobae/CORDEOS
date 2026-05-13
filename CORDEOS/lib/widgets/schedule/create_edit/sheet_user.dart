import 'package:cordeos/models/domain/schedule.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class UsersList extends StatelessWidget {
  final dynamic scheduleId;
  final Role role;
  final bool canEdit;

  const UsersList({
    super.key,
    required this.scheduleId,
    required this.role,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final user in role.users) ...[
          Divider(color: colorScheme.surfaceContainerLowest, height: 1),
          _buildMemberCard(context, user),
        ],
        if (canEdit)
          FilledTextButton(
            text: l10n.clear,
            isDense: true,
            isDark: true,
            onPressed: () {
              context.read<LocalScheduleProvider>().clearUsersFromRole(
                scheduleId,
                role.id,
              );
            },
          ),
      ],
    );
  }

  Widget _buildMemberCard(BuildContext context, User user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(user.username, style: textTheme.titleSmall),
              Text(user.email, style: textTheme.bodySmall),
              SizedBox(height: 4),
            ],
          ),
        ),
        if (canEdit)
          IconButton(
            onPressed: () {
              final localSch = context.read<LocalScheduleProvider>();

              localSch.removeUserFromRole(scheduleId, role.id, user.id!);
            },
            icon: Icon(Icons.remove_circle_outline),
            color: colorScheme.error,
          ),
      ],
    );
  }
}
