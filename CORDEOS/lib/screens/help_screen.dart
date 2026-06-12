import 'package:cordeos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.underDevelopment));
  }
}
