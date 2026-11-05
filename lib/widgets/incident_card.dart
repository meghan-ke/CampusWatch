// lib/widgets/incident_card.dart
// One report shown as a card in a list: photo (or category icon), title,
// location, date and status chip.
//
// Usage:
//   IncidentCard(incident: incident, onTap: () { ... })

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';
import '../utils/app_theme.dart';
import 'status_chip.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, this.onTap});

  final Incident incident;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(incident: incident),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            incident.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('d MMM yyyy, HH:mm')
                                .format(incident.createdAt),
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ),
                        StatusChip(status: incident.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First photo of the report, or the category icon when there is none.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 64,
      height: 64,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(incident.category.icon, color: AppColors.primary),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: incident.imageUrls.isEmpty
          ? fallback
          : Image.network(
              incident.imageUrls.first,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}