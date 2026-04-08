import 'package:cordeos/providers/bug_report_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:cordeos/models/domain/bug_report.dart';
import 'package:cordeos/providers/settings/app_info_provider.dart';

import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({super.key});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reproductionController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  BugSeverity? severity;

  @override
  void initState() {
    super.initState();
    _titleController.text = '';
    _descriptionController.text = '';
    _reproductionController.text = '';
    _expectedController.text = '';
    _actualController.text = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reproductionController.dispose();
    _expectedController.dispose();
    _actualController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        spacing: 24,
        children: [
          // HEADER
          Text(
            AppLocalizations.of(context)!.reportBug,
            style: textTheme.titleMedium,
          ),

          // FORM
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                children: [
                  // TITLE
                  LabeledTextField(
                    controller: _titleController,
                    label: AppLocalizations.of(context)!.title,
                  ),

                  // BUG DESCRIPTION
                  LabeledTextField(
                    controller: _descriptionController,
                    label: AppLocalizations.of(context)!.description,
                  ),

                  // EXPECTED VS ACTUAL BEHAVIOR
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.behavior,
                        style: textTheme.labelLarge,
                      ),
                      Row(
                        spacing: 16,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: LabeledTextField(
                              controller: _expectedController,
                              label: AppLocalizations.of(context)!.expected,
                              isDense: true,
                              lineCount: 3,
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                          Expanded(
                            child: LabeledTextField(
                              controller: _actualController,
                              label: AppLocalizations.of(context)!.actual,
                              isDense: true,
                              lineCount: 3,
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // REPRODUCTION STEPS
                  LabeledTextField(
                    label: AppLocalizations.of(context)!.stepsToReproduce,
                    controller: _reproductionController,
                    lineCount: 3,
                    keyboardType: TextInputType.multiline,
                  ),

                  // SEVERITY SELECTION
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.severity,
                        style: textTheme.labelLarge,
                      ),
                      DropdownButtonFormField<BugSeverity>(
                        onChanged: (value) => setState(() => severity = value),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.shadow),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.surfaceContainer,
                            ),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        items: BugSeverity.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s.label(context),
                              style: textTheme.bodyLarge,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // SUBMIT BUTTON
          Consumer<BugReportProvider>(
            builder: (context, bug, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bug.isReporting)
                    const Center(child: CircularProgressIndicator()),
                  FilledTextButton(
                    text: AppLocalizations.of(context)!.report,
                    isDisabled: bug.isReporting,
                    isDark: true,
                    onPressed: _reportBug(bug),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  VoidCallback _reportBug(BugReportProvider bug) {
    final colorScheme = Theme.of(context).colorScheme;

    return () async {
      final appInfo = context.read<AppInfoProvider>();
      final nav = context.read<NavigationProvider>();
      final networkState = await appInfo.getNetworkState();

      final report = BugReport(
        title: _titleController.text,
        description: _descriptionController.text,
        expectedBehavior: _expectedController.text,
        actualBehavior: _actualController.text,
        reproductionSteps: _reproductionController.text,
        severity: severity ?? BugSeverity.low,
        deviceInfo: appInfo.deviceInfo,
        appVersion: appInfo.appVersionWithBuild,
        networkState: networkState,
      );

      final success = await bug.reportBug(report);

      if (mounted) {
        if (success) {
          // Success feedback
          nav.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.bugReportSuccess),
            ),
          );
        } else {
          // Failure feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.errorContainer,
              content: Text(
                bug.error ?? '',
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          );
        }
      }
    };
  }
}
