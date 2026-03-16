import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/playlist/flow_item.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayFlowItem extends StatelessWidget {
  final FlowItem flowItem;

  const PlayFlowItem({super.key, required this.flowItem});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<LayoutSettingsProvider>(
      builder: (context, layoutSettings, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 24.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              // HEADER
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  Text(flowItem.title, style: textTheme.titleMedium),
                  Text(
                    '${AppLocalizations.of(context)!.estimatedTime}: ${DateTimeUtils.formatDuration(flowItem.duration)}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.surfaceContainerLow,
                        width: 1.2,
                      ),
                      left: BorderSide(
                        color: colorScheme.surfaceContainerLow,
                        width: 1.2,
                      ),
                      right: BorderSide(
                        color: colorScheme.surfaceContainerLow,
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.surfaceContainerLow,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.annotations,
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily:
                                layoutSettings.lyricTextStyle.fontFamily,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            flowItem.contentText,
                            style: textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              fontFamily:
                                  layoutSettings.lyricTextStyle.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
