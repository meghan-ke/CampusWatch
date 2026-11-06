// lib/widgets/status_timeline.dart
// Draws an incident's status history as a vertical timeline:
// one dot per change, with the note, who made it and when.
// The last entry is the current status and is drawn larger.
//
// Usage:
//   StatusTimeline(history: incident.statusHistory)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';
import '../utils/app_theme.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.history});

  /// Oldest first (as stored in Firestore).
  final List<StatusUpdate> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const Text('No updates yet.');

    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _TimelineEntry(
            update: history[i],
            isLast: i == history.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.update, required this.isLast});

  final StatusUpdate update;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forStatus(update.status);
    final textTheme = Theme.of(context).textTheme;
    final dotSize = isLast ? 18.0 : 14.0;

    // IntrinsicHeight lets the connecting line stretch to the text's height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column: the dot and the line down to the next entry.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isLast
                        ? Border.all(color: color.withValues(alpha: 0.3), width: 4)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          // Right column: what happened.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.status.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (update.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(update.note),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${update.changedBy} · '
                    '${DateFormat('d MMM yyyy, HH:mm').format(update.changedAt)}',
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}