// lib/models/enums.dart
// The fixed sets of choices used across the app.
//
// Each enum is stored in Firestore as plain text (its `name`, e.g. "inProgress")
// and converted back with `fromString`. Each also has a `label` for the UI.

import 'package:flutter/material.dart';

/// Who is using the app. Students report issues; staff review and update them.
/// Role is stored in the user's Firestore document and enforced by
/// firestore.rules (see docs/ROLES_AND_ACCESS in the docs).
enum UserRole {
  student('Student'),
  staff('Staff');

  const UserRole(this.label);
  final String label;

  bool get isStaff => this == UserRole.staff;

  /// Converts stored text back to a role. Unknown values become `student`,
  /// the safest default (least privileges).
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }
}

/// The type of problem being reported.
enum IncidentCategory {
  water('Water', Icons.water_drop),
  electricity('Electricity', Icons.bolt),
  facilities('Facilities', Icons.apartment),
  furniture('Furniture', Icons.chair),
  sanitation('Sanitation', Icons.cleaning_services),
  safety('Safety', Icons.shield),
  other('Other', Icons.more_horiz);

  const IncidentCategory(this.label, this.icon);
  final String label;
  final IconData icon;

  static IncidentCategory fromString(String? value) {
    return IncidentCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => IncidentCategory.other,
    );
  }
}

/// Where a report is in its life cycle. Order matters: a report normally
/// moves from the first value to the last.
enum IncidentStatus {
  submitted('Submitted'),
  underReview('Under review'),
  inProgress('In progress'),
  resolved('Resolved');

  const IncidentStatus(this.label);
  final String label;

  static IncidentStatus fromString(String? value) {
    return IncidentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}