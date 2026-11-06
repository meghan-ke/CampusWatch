// lib/screens/home_screen.dart
// The signed-in shell of the app: a bottom navigation bar that switches
// between Home (dashboard), Reports (browse/search/filter) and Profile.
// Students also get a "Report" button to submit a new incident.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'incident_list_screen.dart';
import 'profile_screen.dart';
import 'report_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0; // which tab is showing

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().isStaff;

    return Scaffold(
      // IndexedStack keeps each tab alive, so a search or scroll position
      // is not lost when switching tabs.
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(onSeeAll: () => setState(() => _index = 1)),
          const IncidentListScreen(),
          const ProfileScreen(),
        ],
      ),

      // Only students submit reports; staff review them.
      floatingActionButton: isStaff
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReportIncidentScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Report'),
            ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}