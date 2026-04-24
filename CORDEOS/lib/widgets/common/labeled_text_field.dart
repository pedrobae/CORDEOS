import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final String? instruction;
  final int lineCount;
  final bool isEnabled;
  final bool obscureText;
  final bool isDense;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final void Function(String)? onSubmitted;

  const LabeledTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.focusNode,
    this.validator,
    this.instruction,
    this.lineCount = 1,
    this.isEnabled = true,
    this.obscureText = false,
    this.isDense = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: isDense ? 4 : 8,
      children: [
        Text(
          label,
          style: isDense ? textTheme.labelSmall : textTheme.labelMedium,
        ),
        TextFormField(
          validator: validator,
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            fillColor: isEnabled
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest,
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.shadow),
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
          onFieldSubmitted: (value) {
            if (onSubmitted != null) {
              onSubmitted!(value);
            }
          },
          textCapitalization: textCapitalization,
        ),
        if (instruction != null)
          Text(
            instruction!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.surfaceContainerLow,
            ),
          ),
      ],
    );
  }
}
