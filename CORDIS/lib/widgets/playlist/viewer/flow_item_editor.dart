import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/playlist/flow_item.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/common/labeled_duration_picker.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';

class FlowItemEditor extends StatefulWidget {
  final int? flowID;
  final int playID;

  const FlowItemEditor({super.key, this.flowID, required this.playID});

  @override
  State<FlowItemEditor> createState() => _FlowItemEditorState();
}

class _FlowItemEditorState extends State<FlowItemEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _durationController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _durationController = TextEditingController();

    _addListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadFlow();
    });
  }

  void _addListeners() {
    if (widget.flowID == null) return;

    final flow = context.read<FlowItemProvider>();
    _titleController.addListener(() {
      flow.cacheTitle(widget.flowID!, _titleController.text);
    });
    _contentController.addListener(() {
      flow.cacheContent(widget.flowID!, _contentController.text);
    });
    _durationController.addListener(() {
      flow.cacheDuration(
        widget.flowID!,
        DateTimeUtils.parseDuration(_durationController.text),
      );
    });
  }

  Future<void> _loadFlow() async {
    if (widget.flowID == null) return;
    final flow = context.read<FlowItemProvider>();

    await flow.loadFlowItem(widget.flowID!);

    final flowItem = flow.getFlowItem(widget.flowID!);
    if (flowItem != null) {
      _titleController.text = flowItem.title;
      _contentController.text = flowItem.contentText;
      _durationController.text = DateTimeUtils.formatDuration(
        flowItem.duration,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nav = context.read<NavigationProvider>();

    return Consumer<FlowItemProvider>(
      builder: (context, flow, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.flowID != null
                  ? AppLocalizations.of(
                      context,
                    )!.editPlaceholder(AppLocalizations.of(context)!.flowItem)
                  : AppLocalizations.of(context)!.createPlaceholder(
                      AppLocalizations.of(context)!.flowItem,
                    ),
              style: textTheme.titleMedium,
            ),
            leading: BackButton(
              onPressed: () {
                nav.attemptPop(context);
              },
            ),
            actions: [
              IconButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  widget.flowID == null
                      ? flow.create(
                          FlowItem(
                            firebaseId: '',
                            playlistId: widget.playID,
                            title: _titleController.text,
                            contentText: _contentController.text,
                            duration: DateTimeUtils.parseDuration(
                              _durationController.text,
                            ),
                            position: 0,
                          ),
                        )
                      : flow.save(widget.flowID!);

                  nav.pop();
                },
                icon: const Icon(Icons.save),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  LabeledTextField(
                    controller: _titleController,
                    label: AppLocalizations.of(context)!.title,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  DurationPickerField(
                    controller: _durationController,
                    label: AppLocalizations.of(context)!.estimatedTime,
                  ),
                  LabeledTextField(
                    controller: _contentController,
                    label: AppLocalizations.of(context)!.optionalPlaceholder(
                      AppLocalizations.of(context)!.annotations,
                    ),
                    lineCount: 7,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
