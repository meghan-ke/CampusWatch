// lib/widgets/app_text_field.dart
// A reusable text input used by the login, register and report forms.
//
// Usage:
//   AppTextField(
//     controller: _emailController,
//     label: 'Email',
//     validator: Validators.email,
//   )

import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
  });

  /// Holds the text the user types. The screen creates and reads it.
  final TextEditingController controller;

  /// Text shown above the input, e.g. "Email".
  final String label;

  /// Returns an error message, or null if valid (see utils/validators.dart).
  final String? Function(String?)? validator;

  /// Optional icon shown at the start of the field.
  final IconData? icon;

  /// Hides the text and shows a show/hide toggle.
  final bool isPassword;

  final TextInputType? keyboardType;

  /// 1 for single-line fields; larger for multi-line (e.g. description).
  final int maxLines;

  /// Optional character limit; also shows a counter under the field.
  final int? maxLength;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Only used for password fields: whether the text is currently hidden.
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword && _obscure,
      // A hidden password field must be single-line.
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}