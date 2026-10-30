import 'package:flutter/material.dart';

/// A labelled text field used for form inputs.
///
/// Renders a small caption ([label]) above a [TextField], optionally with
/// obscured input (for passwords) and a controller supplied by the caller.
class CustomTextField extends StatelessWidget {
  /// Caption shown above the input field.
  final String label;

  /// Placeholder text displayed when the field is empty.
  final String hint;

  /// When `true`, the input is masked (e.g. for passwords).
  final bool obscureText;

  /// Optional controller for reading or setting the field's value.
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Vertical layout: label, small gap, then the text field itself.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscureText,
          // Only hint styling is overridden here; borders, fill colour,
          // and padding come from [AppTheme.inputDecorationTheme].
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}