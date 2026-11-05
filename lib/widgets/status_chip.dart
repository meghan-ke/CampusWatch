// lib/widgets/status_chip.dart
// A small colored label showing an incident's status.
// Text comes from IncidentStatus.label (models/enums.dart) and color from
// AppColors.forStatus (utils/app_theme.dart), so it always matches the timeline.
//
// Usage:
//   StatusChip(status: incident.status)

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../utils/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // A light tint of the status color as the background...
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      // ...and the full color for the text, so it stays readable.
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}