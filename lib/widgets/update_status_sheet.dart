// lib/widgets/update_status_sheet.dart
// Bottom sheet where STAFF choose a new status for a report and add a note.
// The change is saved by IncidentProvider.updateStatus, which also adds an
// entry to the incident's history (shown in the timeline).
//
// Usage:
//   showUpdateStatusSheet(context, incident);

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/incident.dart';
import '../providers/incident_provider.dart';
import '../utils/app_theme.dart';
import 'primary_button.dart';

/// Opens the sheet. Call this from the detail screen (staff only).
Future<void> showUpdateStatusSheet(BuildContext context, Incident incident) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // lets the sheet rise above the keyboard
    showDragHandle: true,
    builder: (_) => UpdateStatusSheet(incident: incident),
  );
}

class UpdateStatusSheet extends StatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});

  final Incident incident;

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  // Starts on the report's current status.
  late IncidentStatus _selected = widget.incident.status;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == widget.incident.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a different status first.')),
      );
      return;
    }

    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await provider.updateStatus(
      incidentId: widget.incident.id,
      newStatus: _selected,
      note: _noteController.text,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to ${_selected.label}.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Update failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<IncidentProvider>().isSubmitting;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // The extra bottom padding keeps the form above the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update status', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.incident.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentStatus.values.map((status) {
                return ChoiceChip(
                  avatar: CircleAvatar(
                    radius: 6,
                    backgroundColor: AppColors.forStatus(status),
                  ),
                  label: Text(status.label),
                  selected: _selected == status,
                  onSelected: (_) => setState(() => _selected = status),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Technician assigned',
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Save status',
              icon: Icons.check,
              isLoading: isSubmitting,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}