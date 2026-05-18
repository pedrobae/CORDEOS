import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/schedule.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/user/email_provider.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';

import 'package:cordeos/widgets/common/filled_text_button.dart';

class ShareScheduleSheet extends StatefulWidget {
  final int scheduleID;

  const ShareScheduleSheet({super.key, required this.scheduleID});

  @override
  State<ShareScheduleSheet> createState() => _ShareScheduleSheetState();
}

class _ShareScheduleSheetState extends State<ShareScheduleSheet> {
  List<String> selectedRoles = [];
  bool copied = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final email = context.read<EmailProvider>();

    return Selector<
      LocalScheduleProvider,
      ({String shareCode, String scheduleName, List<Role> roles})
    >(
      selector: (context, localSch) {
        final schedule = localSch.getSchedule(widget.scheduleID);
        if (schedule == null) {
          throw Exception(
            "SHARE SHEET - Schedule not found for ID ${widget.scheduleID}",
          );
        }
        return (
          shareCode: schedule.shareCode,
          scheduleName: schedule.name,
          roles: schedule.roles,
        );
      },

      builder: (context, s, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                // Share code
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.shareCode,
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      SelectableText(
                        s.shareCode,
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      FilledTextButton(
                        isDense: true,
                        text: copied
                            ? AppLocalizations.of(context)!.codeCopied
                            : AppLocalizations.of(context)!.copyCode,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: s.shareCode));
                          setState(() {
                            copied = true;
                          });
                          Future.delayed(Duration(seconds: 2), () {
                            setState(() {
                              copied = false;
                            });
                          });
                        },
                        isDark: true,
                        isDisabled: copied == true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.sendToRoleMembers,
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    for (var role in s.roles)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(color: colorScheme.onSurface),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Checkbox(
                              visualDensity: VisualDensity.compact,
                              activeColor: colorScheme.shadow,
                              value: selectedRoles.contains(role.name),
                              onChanged: (bool? isChecked) {
                                _toggleRole(role.name, isChecked);
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(role.name, style: textTheme.titleMedium),
                                  Text(
                                    role.users.isEmpty
                                        ? AppLocalizations.of(
                                            context,
                                          )!.noMembers
                                        : AppLocalizations.of(
                                            context,
                                          )!.xMembers(role.users.length),
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 32),

                // ACTIONS
                // sendInvites
                FilledTextButton(
                  text: AppLocalizations.of(context)!.sendInvites,
                  isDark: true,
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final successfulMessage = AppLocalizations.of(
                      context,
                    )!.inviteSentSuccessfully;
                    final failureMessage = AppLocalizations.of(context)!
                        .errorMessage(
                          AppLocalizations.of(context)!.sendInvites,
                          email.error ?? 'Unknown error',
                        );
                    Navigator.of(context).pop();

                    final bool success = await email.sendInvites(
                      s.shareCode,
                      s.scheduleName,
                      s.roles,
                      selectedRoles,
                      EmailStrings(
                        invitationGreeting: (String username) =>
                            AppLocalizations.of(
                              context,
                            )!.invitationGreeting(username),
                        invitationMessage:
                            (String scheduleName, String roleName) =>
                                AppLocalizations.of(
                                  context,
                                )!.invitationMessage(scheduleName, roleName),
                        instructions: (String shareCode) => AppLocalizations.of(
                          context,
                        )!.instructions(shareCode),
                        contactSupport: AppLocalizations.of(
                          context,
                        )!.contactSupport,
                        bestRegards: AppLocalizations.of(context)!.bestRegards,
                        invitationSubject:
                            (String scheduleName, String roleName) =>
                                AppLocalizations.of(
                                  context,
                                )!.invitationSubject(scheduleName, roleName),
                      ),
                    );
                    if (success) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          backgroundColor: colorScheme.primary,
                          content: Text(
                            successfulMessage,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.amber,
                          content: Text(
                            failureMessage,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleRole(String roleName, bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        selectedRoles.add(roleName);
      } else {
        selectedRoles.remove(roleName);
      }
    });
  }
}
