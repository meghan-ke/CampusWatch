// lib/widgets/primary_button.dart
// The main action button of a screen (Login, Register, Submit report...).
// Shows a spinner and ignores taps while [isLoading] is true.
//
// Usage:
//   PrimaryButton(
//     label: 'Login',
//     isLoading: authProvider.isLoading,
//     onPressed: _submit,
//   )

import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;

  /// What happens on tap. Ignored while loading.
  final VoidCallback? onPressed;

  /// When true, shows a spinner instead of the label.
  final bool isLoading;

  /// Optional icon shown before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Colors, size and shape come from AppTheme (elevatedButtonTheme).
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}