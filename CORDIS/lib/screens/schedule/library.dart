import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/schedule/cloud_schedule_provider.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/widgets/schedule/library/scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleLibraryScreen extends StatefulWidget {
  const ScheduleLibraryScreen({super.key});

  @override
  State<ScheduleLibraryScreen> createState() => _ScheduleLibraryScreenState();
}

class _ScheduleLibraryScreenState extends State<ScheduleLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localSch = context.read<LocalScheduleProvider>();
      final cloudSch = context.read<CloudScheduleProvider>();
      final auth = context.read<MyAuthProvider>();

      if (mounted) {
        await localSch.loadSchedules();
        await cloudSch.loadSchedules(auth.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          _buildSearchBar(context),
          const Expanded(child: ScheduleScrollView()),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final localSch = context.read<LocalScheduleProvider>();
    final cloudSch = context.read<CloudScheduleProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchSchedule,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.surfaceContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        suffixIcon: const Icon(Icons.search),
        fillColor: colorScheme.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      ),
      onChanged: (value) {
        localSch.setSearchTerm(value);
        cloudSch.setSearchTerm(value);
      },
    );
  }
}
