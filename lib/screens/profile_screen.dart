// lib/screens/profile_screen.dart
// The Profile tab: a gradient header with the user's name and report counts,
// info cards (role, email, account status) and sign out.
// Students also see their own reports below ("My reports").

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IncidentProvider>();
    final user = auth.user;
    // During logout the user briefly becomes null; draw nothing then.
    if (user == null) return const SizedBox.shrink();

    final isStaff = user.role.isStaff;
    // Students count their own reports; staff count everything.
    final source = isStaff ? provider.allIncidents : provider.myIncidents;
    final verified = isStaff || auth.emailVerified;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            name: user.name,
            email: user.email,
            totalLabel: isStaff ? 'All reports' : 'Total reports',
            total: source.length,
            inProgress:
                provider.countByStatus(IncidentStatus.inProgress, from: source),
            resolved:
                provider.countByStatus(IncidentStatus.resolved, from: source),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Info card -----------------------------------------------
                _InfoCard(
                  rows: [
                    _InfoRow(
                      icon: isStaff
                          ? Icons.admin_panel_settings_outlined
                          : Icons.school_outlined,
                      label: 'Role',
                      value: user.role.label,
                    ),
                    _InfoRow(
                      icon: Icons.alternate_email,
                      label: 'Email',
                      value: user.email,
                    ),
                    _InfoRow(
                      icon: verified
                          ? Icons.verified_user_outlined
                          : Icons.warning_amber_rounded,
                      label: 'Account',
                      value: isStaff
                          ? 'Staff account'
                          : verified
                              ? 'Verified ALU account'
                              : 'Email not verified',
                      valueColor: verified
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF9A825),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Sign out --------------------------------------------------
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.white,
                  ),
                ),

                // --- Own reports (students only) -------------------------------
                if (!isStaff) ...[
                  const SizedBox(height: 24),
                  Text(
                    'My reports (${source.length})',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (source.isEmpty)
                    const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No reports yet',
                      message: 'Reports you submit will appear here.',
                    )
                  else
                    for (final incident in source) ...[
                      IncidentCard(
                        incident: incident,
                        onTap: () =>
                            IncidentDetailScreen.open(context, incident.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                  // Space so the floating Report button never covers the list.
                  const SizedBox(height: 70),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient banner: name, email, initials avatar and three count tiles.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.totalLabel,
    required this.total,
    required this.inProgress,
    required this.resolved,
  });

  final String name;
  final String email;
  final String totalLabel;
  final int total;
  final int inProgress;
  final int resolved;

  /// "Keza Meghan" -> "KM"
  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the content below the status bar, since this screen has no AppBar.
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color.lerp(AppColors.primary, Colors.black, 0.35)!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatTile(count: total, label: totalLabel),
              _StatTile(count: inProgress, label: 'In progress'),
              _StatTile(count: resolved, label: 'Resolved'),
            ],
          ),
        ],
      ),
    );
  }
}

/// One translucent count box inside the header.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// A white rounded card holding rows separated by thin dividers.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

/// Icon in a tinted square, a small grey label and a bold value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}