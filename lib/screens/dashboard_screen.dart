// lib/screens/dashboard_screen.dart
// The Home tab: greeting, a call-to-action banner, summary counts and the
// most recent reports.
//   - Students see THEIR reports and a "Report an issue" banner.
//   - Staff see ALL reports and a "Review reports" banner.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';
import 'report_incident_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onSeeAll});

  /// Switches HomeScreen to the Reports tab.
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IncidentProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final isStaff = user.role.isStaff;
    final textTheme = Theme.of(context).textTheme;

    // Students count their own reports; staff count everything.
    final source = isStaff ? provider.allIncidents : provider.myIncidents;
    final recent = source.take(3).toList(); // list is already newest first
    final firstName = user.name.trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hello, $firstName 👋',
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isStaff
                ? 'Review reports and keep students informed.'
                : 'Help make our campus safer. Report issues and track them.',
          ),
          const SizedBox(height: 16),

          // --- Banner ----------------------------------------------------------
          _Banner(
            title: isStaff
                ? '${provider.countByStatus(IncidentStatus.submitted)} new '
                    'report(s) waiting'
                : 'See an issue on campus?',
            subtitle: isStaff
                ? 'Open a report to review it and update its status.'
                : 'Report it and help improve our learning environment.',
            buttonLabel: isStaff ? 'Review reports' : 'Report an issue',
            buttonIcon: isStaff ? Icons.fact_check_outlined : Icons.add_circle,
            onPressed: isStaff
                ? onSeeAll
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportIncidentScreen(),
                      ),
                    ),
          ),
          const SizedBox(height: 20),

          // --- Summary counts ------------------------------------------------------
          Text(
            isStaff ? 'All reports' : 'My report summary',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryTile(
                icon: Icons.description_outlined,
                color: AppColors.primary,
                count: source.length,
                label: 'Total',
              ),
              _SummaryTile(
                icon: Icons.hourglass_empty,
                color: AppColors.forStatus(IncidentStatus.submitted),
                count: provider.countByStatus(IncidentStatus.submitted,
                    from: source),
                label: 'Submitted',
              ),
              _SummaryTile(
                icon: Icons.build_outlined,
                color: AppColors.forStatus(IncidentStatus.inProgress),
                count: provider.countByStatus(IncidentStatus.inProgress,
                    from: source),
                label: 'In progress',
              ),
              _SummaryTile(
                icon: Icons.check_circle_outline,
                color: AppColors.forStatus(IncidentStatus.resolved),
                count: provider.countByStatus(IncidentStatus.resolved,
                    from: source),
                label: 'Resolved',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- Recent reports -----------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text('Recent reports', style: textTheme.titleMedium),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 6),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recent.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: isStaff
                  ? 'New reports will appear here.'
                  : 'Tap "Report an issue" to submit your first one.',
            )
          else
            for (final incident in recent) ...[
              IncidentCard(
                incident: incident,
                onTap: () => IncidentDetailScreen.open(context, incident.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

/// The colored call-to-action card at the top of the dashboard.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
            // White button, because the banner itself is the primary color.
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One small count box (e.g. "5 In progress").
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}