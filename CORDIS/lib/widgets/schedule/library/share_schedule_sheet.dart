import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/email_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ShareScheduleSheet extends StatefulWidget {
  final dynamic scheduleId;

  const ShareScheduleSheet({super.key, required this.scheduleId});

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

    return Consumer6<
      LocalScheduleProvider,
      CloudScheduleProvider,
      UserProvider,
      MyAuthProvider,
      PlaylistProvider,
      EmailProvider
    >(
      builder:
          (
            context,
            localScheduleProvider,
            cloudScheduleProvider,
            userProvider,
            authProvider,
            playlistProvider,
            emailProvider,
            child,
          ) {
            final dynamic schedule = (widget.scheduleId is int)
                ? localScheduleProvider.getSchedule(widget.scheduleId)
                : cloudScheduleProvider.getSchedule(widget.scheduleId);

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
              ),
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
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
                            schedule.shareCode,
                            style: textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          FilledTextButton(
                            isDense: true,
                            text: copied
                                ? AppLocalizations.of(context)!.codeCopied
                                : AppLocalizations.of(context)!.copyCode,
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: schedule.shareCode),
                              );
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
                        for (var role in schedule.roles)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.name,
                                        style: textTheme.titleMedium,
                                      ),
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
                              emailProvider.error ?? 'Unknown error',
                            );
                        Navigator.of(context).pop();

                        final bool success = await emailProvider.sendInvites(
                          schedule,
                          selectedRoles,
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
