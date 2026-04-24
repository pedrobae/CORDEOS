import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/widgets/schedule/create_edit/sheet_add_user.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

class UsersBottomSheet extends StatefulWidget {
  final int scheduleId;
  final int roleID;

  const UsersBottomSheet({
    super.key,
    required this.scheduleId,
    required this.roleID,
  });

  @override
  State<UsersBottomSheet> createState() => _UsersBottomSheetState();
}

class _UsersBottomSheetState extends State<UsersBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Selector<LocalScheduleProvider, ({String? name, int memberCount})>(
      selector: (context, localSch) {
        final role = localSch
            .getSchedule(widget.scheduleId)!
            .roles[widget.roleID];

        return (name: role?.name, memberCount: role?.users.length ?? 0);
      },
      builder: (context, s, child) {
        if (s.name == null) {
          return Center(child: Text(l10n.error));
        }
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
                    l10n.assignMembersToRole(s.name!),
                    style: textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              FilledTextButton(
                text: l10n.addPlaceholder(l10n.member),
                onPressed: _openAddUserSheet(),
                icon: Icons.add,
                isDense: true,
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    if (s.memberCount == 0)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(
                            color: colorScheme.surfaceContainerLowest,
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Center(child: Text(l10n.noMembers)),
                      ),
                    for (int i = 0; i < s.memberCount; i++) ...[
                      _buildMemberCard(i),
                    ],
                  ],
                ),
              ),
              FilledTextButton(
                text: l10n.clear,
                onPressed: () {
                  context.read<LocalScheduleProvider>().clearUsersFromRole(
                    widget.scheduleId,
                    widget.roleID,
                  );
                },
                isDense: true,
              ),
              SizedBox(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector<LocalScheduleProvider, User?>(
      selector: (context, localSch) {
        final schedule = localSch.getSchedule(widget.scheduleId);

        return schedule?.roles[widget.roleID]?.users[index];
      },
      builder: (context, member, child) {
        if (member == null) {
          return Center(child: Text(AppLocalizations.of(context)!.error));
        }
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            border: Border.all(
              color: colorScheme.surfaceContainerLowest,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      member.email,
                      style: TextStyle(fontSize: 14, color: colorScheme.shadow),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final localSch = context.read<LocalScheduleProvider>();

                  localSch.removeUserFromRole(
                    widget.scheduleId,
                    widget.roleID,
                    member.id!,
                  );
                },
                icon: Icon(Icons.remove_circle_outline),
                color: colorScheme.error,
              ),
            ],
          ),
        );
      },
    );
  }

  VoidCallback _openAddUserSheet() {
    return () => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddUserSheet(
            scheduleId: widget.scheduleId,
            roleID: widget.roleID,
          ),
        );
      },
    );
  }
}
