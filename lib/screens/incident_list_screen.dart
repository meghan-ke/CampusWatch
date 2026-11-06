// lib/screens/incident_list_screen.dart
// Browse all reports, with a search box and status/category filters.
// The filtering itself happens in IncidentProvider; this screen only shows
// the result and sends the user's choices to the provider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/incident_provider.dart';
import 'incident_detail_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final incidents = provider.incidents;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          // --- Search ---------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search title, description or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: provider.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      ),
              ),
            ),
          ),

          // --- Status filter ----------------------------------------------------
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: provider.statusFilter == null,
                  onSelected: () => provider.setStatusFilter(null),
                ),
                for (final status in IncidentStatus.values)
                  _FilterChip(
                    label: status.label,
                    selected: provider.statusFilter == status,
                    onSelected: () => provider.setStatusFilter(
                      provider.statusFilter == status ? null : status,
                    ),
                  ),
              ],
            ),
          ),

          // --- Category filter --------------------------------------------------
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final category in IncidentCategory.values)
                  _FilterChip(
                    label: category.label,
                    icon: category.icon,
                    selected: provider.categoryFilter == category,
                    onSelected: () => provider.setCategoryFilter(
                      provider.categoryFilter == category ? null : category,
                    ),
                  ),
              ],
            ),
          ),

          // --- Results ----------------------------------------------------------
          Expanded(child: _buildResults(provider, incidents)),
        ],
      ),
    );
  }

  Widget _buildResults(IncidentProvider provider, List incidents) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.allIncidents.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Something went wrong',
        message: provider.errorMessage,
      );
    }

    if (incidents.isEmpty) {
      final filtering = provider.hasActiveFilters;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: filtering ? Icons.search_off : Icons.inbox_outlined,
            title: filtering ? 'No matching reports' : 'No reports yet',
            message: filtering
                ? 'Try a different search or clear the filters.'
                : 'Reports will appear here once they are submitted.',
          ),
          if (filtering)
            TextButton(
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
              child: const Text('Clear filters'),
            ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: incidents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return IncidentCard(
          incident: incident,
          // Step 7 will open the detail screen here.
          onTap: () => IncidentDetailScreen.open(context, incident.id),
        );
      },
    );
  }
}

/// A selectable chip used by both filter rows.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}