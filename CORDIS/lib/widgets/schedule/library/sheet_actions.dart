import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/schedule/create.dart';
import 'package:cordis/screens/schedule/share_code_screen.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleActionsSheet extends StatelessWidget {
  const ScheduleActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();
    final sel = context.read<SelectionProvider>();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.addPlaceholder(AppLocalizations.of(context)!.schedule),
                style: textTheme.titleMedium,
              ),
              CloseButton(onPressed: () => Navigator.of(context).pop()),
            ],
          ),

          // ACTIONS
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CREATE FROM SCRATCH BUTTON
              FilledTextButton(
                text: AppLocalizations.of(
                  context,
                )!.createPlaceholder(AppLocalizations.of(context)!.schedule),
                trailingIcon: Icons.chevron_right,
                isDark: true,
                onPressed: () {
                  final localScheduleProvider = context
                      .read<LocalScheduleProvider>();
                  Navigator.of(context).pop(); // Close the bottom sheet
                  sel.enableSelectionMode(); // For playlist assignment
                  nav.push(
                    () => CreateScheduleScreen(creationStep: 1),
                    showBottomNavBar: true,
                    changeDetector: () =>
                        localScheduleProvider.hasUnsavedChanges,
                    onChangeDiscarded: () =>
                        localScheduleProvider.loadSchedule(-1),
                    onPopCallback: () {
                      sel.disableSelectionMode();
                    },
                  );
                },
              ),

              // IMPORT FROM SHARE CODE BUTTON
              FilledTextButton(
                text: AppLocalizations.of(context)!.shareCode,
                trailingIcon: Icons.chevron_right,
                onPressed: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  nav.push(
                    () => ShareCodeScreen(
                      onBack: (_) {
                        nav.attemptPop(context);
                      },
                      onSuccess: (_) {
                        nav.pop(); // Close the share code screen
                      },
                    ),
                    showBottomNavBar: true,
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
