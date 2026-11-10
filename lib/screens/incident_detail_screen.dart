// lib/screens/incident_detail_screen.dart
// Shows one report in full, laid out as cards:
// photos, title + progress, key facts, description and the status timeline.
// Staff also get a pinned "Update status" button.
//
// The screen receives only the incident's id and reads the report from
// IncidentProvider, so it updates live when a status changes.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';
import '../widgets/update_status_sheet.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  /// Shortcut used by every list and card to open this screen.
  static void open(BuildContext context, String incidentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncidentDetailScreen(incidentId: incidentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStaff = auth.isStaff;
    final all = context.watch<IncidentProvider>().allIncidents;
    final matches = all.where((incident) => incident.id == incidentId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident details')),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Report not found',
          message: 'It may have been removed.',
        ),
      );
    }

    final incident = matches.first;
    final canDelete = isStaff ||
      (incident.reporterId == auth.user?.uid &&
        incident.status == IncidentStatus.submitted);
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident details'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete report',
              onPressed: () => _confirmDelete(context, incident),
            ),
        ],
      ),

      // Pinned button, only for staff.
      bottomNavigationBar: isStaff
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8E2E4))),
              ),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  label: 'Update status',
                  icon: Icons.edit_note,
                  onPressed: () => showUpdateStatusSheet(context, incident),
                ),
              ),
            )
          : null,

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Photos, or a category banner when there are none ---------------
          if (incident.imageUrls.isNotEmpty)
            _PhotoGallery(urls: incident.imageUrls)
          else
            _CategoryBanner(category: incident.category),
          const SizedBox(height: 16),

          // --- Title, category and progress -------------------------------------
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        incident.title,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: incident.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(incident.category.icon,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      incident.category.label,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProgressSteps(status: incident.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Key facts -------------------------------------------------------------
          _Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: incident.location,
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Reported by',
                  value: incident.reporterName,
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Submitted',
                  value: dateFormat.format(incident.createdAt),
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.update,
                  label: 'Last updated',
                  value: dateFormat.format(incident.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Description -------------------------------------------------------------
          _Card(
            title: 'Description',
            child: Text(incident.description),
          ),
          const SizedBox(height: 16),

          // --- Timeline ------------------------------------------------------------------
          _Card(
            title: 'Status timeline',
            child: StatusTimeline(history: incident.statusHistory),
          ),
        ],
      ),
    );
  }
}

/// A white rounded card with an optional bold title.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Icon in a tinted square, a small grey label and the value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four steps (Submitted -> Resolved) with the reached ones filled in.
class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = IncidentStatus.values;
    final current = steps.indexOf(status);
    final inactive = Colors.grey.shade300;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Line coming from the previous step (none for the first).
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= current ? AppColors.primary : inactive),
                      ),
                    ),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          i <= current ? AppColors.primary : inactive,
                      child: Icon(
                        i <= current ? Icons.check : Icons.circle,
                        size: i <= current ? 14 : 6,
                        color: Colors.white,
                      ),
                    ),
                    // Line going to the next step (none for the last).
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == steps.length - 1
                            ? Colors.transparent
                            : (i < current ? AppColors.primary : inactive),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        i == current ? FontWeight.bold : FontWeight.normal,
                    color: i <= current ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Shown instead of the gallery when a report has no photos.
class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.category});

  final IncidentCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(category.icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 6),
          const Text('No photos attached',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Swipeable photos with dots. Tapping a photo opens it full screen.
class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.urls});

  final List<String> urls;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreen(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImage(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final url = widget.urls[index];
                return GestureDetector(
                  onTap: () => _openFullScreen(url),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
            // Page dots, only when there is more than one photo.
            if (widget.urls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
                      Container(
                        width: i == _index ? 18 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A black full-screen viewer with pinch-to-zoom.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Asks for confirmation, then deletes the report and closes the screen.
Future<void> _confirmDelete(BuildContext context, Incident incident) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this report?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final provider = context.read<IncidentProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final success = await provider.deleteIncident(incident);
  if (success) {
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Report deleted.')));
  } else {
    messenger.showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'Delete failed.')),
    );
  }
}