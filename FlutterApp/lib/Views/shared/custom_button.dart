import 'package:flutter/material.dart';

/// A reusable button that renders either a filled [ElevatedButton] or an
/// [OutlinedButton] depending on [isOutlined].
///
/// Intended for simple call-to-action buttons where only the label, tap
/// handler, and style variant need to be configured by the caller.
class CustomButton extends StatelessWidget {
  /// Text shown inside the button.
  final String text;

  /// Tap handler. When `null`, the button is rendered in its disabled state.
  final VoidCallback? onPressed;

  /// Whether to render the outlined variant (`true`) or the filled variant
  /// (`false`, default).
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Outlined variant: dark border, pill shape, dark-grey label.
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }

    // Filled variant: inherits styling from [ThemeData.elevatedButtonTheme].
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}