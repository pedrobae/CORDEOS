import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/selection_provider.dart';
import 'package:cordis/screens/schedule/create_new_schedule.dart';
import 'package:cordis/screens/user/share_code_screen.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleActionsSheet extends StatelessWidget {
  const ScheduleActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<NavigationProvider, SelectionProvider>(
      builder: (context, navigationProvider, selectionProvider, child) {
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
                    text: AppLocalizations.of(context)!.createPlaceholder(
                      AppLocalizations.of(context)!.schedule,
                    ),
                    trailingIcon: Icons.chevron_right,
                    isDark: true,
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                      selectionProvider
                          .enableSelectionMode(); // For playlist assignment
                      navigationProvider.push(
                        CreateScheduleScreen(creationStep: 1),
                        showBottomNavBar: true,
                        changeDetector: () => context.read<LocalScheduleProvider>().hasUnsavedChanges,
                        onPopCallback: () {
                          selectionProvider.disableSelectionMode();
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
                      navigationProvider.push(
                        ShareCodeScreen(
                          onBack: (_) {
                            navigationProvider.attemptPop(context);
                          },
                          onSuccess: (_) {
                            navigationProvider
                                .pop(); // Close the share code screen
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
      },
    );
  }
}
