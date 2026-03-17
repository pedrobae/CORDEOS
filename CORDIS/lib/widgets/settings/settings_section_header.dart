import 'package:flutter/material.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
