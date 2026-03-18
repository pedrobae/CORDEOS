import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? instruction;
  final int lineCount;
  final bool isEnabled;
  final bool obscureText;
  final bool isDense;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const LabeledTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.instruction,
    this.lineCount = 1,
    this.isEnabled = true,
    this.obscureText = false,
    this.isDense = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: isDense ? 4 : 8,
        children: [
          Text(label, style: isDense ? textTheme.labelMedium: textTheme.labelLarge),
          TextFormField(
            validator: validator,
            controller: controller,
            decoration: InputDecoration(
              fillColor: isEnabled
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest,
              hintText: hint,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.shadow),
                borderRadius: BorderRadius.circular(0),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.surfaceContainer),
                borderRadius: BorderRadius.circular(0),
              ),
              visualDensity: VisualDensity.compact,
            ),
            maxLines: lineCount,

            keyboardType: keyboardType,
            enabled: isEnabled,
            obscureText: obscureText,
          ),
          if (instruction != null)
            Text(
              instruction!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.surfaceContainerLow,
              ),
            ),
        ],
      ),
    );
  }
}
