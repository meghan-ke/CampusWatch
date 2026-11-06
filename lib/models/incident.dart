// lib/models/incident.dart
// Describes one reported incident and its status history.
// Stored in Firestore at incidents/{id}. See docs/FIREBASE_SCHEMA.md.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// One entry in an incident's history, e.g. "staff moved it to In progress".
/// The list of these entries powers the status timeline on the detail screen.
class StatusUpdate {
  const StatusUpdate({
    required this.status,
    required this.note,
    required this.changedBy,
    required this.changedAt,
  });

  final IncidentStatus status;

  /// Optional message from the person who made the change.
  final String note;

  /// Display name of the person who made the change.
  final String changedBy;
  final DateTime changedAt;

  factory StatusUpdate.fromMap(Map<String, dynamic> map) {
    return StatusUpdate(
      status: IncidentStatus.fromString(map['status'] as String?),
      note: map['note'] as String? ?? '',
      changedBy: map['changedBy'] as String? ?? '',
      changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'note': note,
      'changedBy': changedBy,
      'changedAt': Timestamp.fromDate(changedAt),
    };
  }
}

/// A campus issue reported by a student.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.imageUrls,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
  });

  /// Firestore document id.
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentStatus status;

  /// Where on campus the problem is, e.g. "Block B, 2nd floor".
  final String location;

  /// Download links of photos stored in Firebase Storage (may be empty).
  final List<String> imageUrls;

  /// uid and display name of the student who reported it.
  final String reporterId;
  final String reporterName;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Oldest first. The first entry is always "Submitted".
  final List<StatusUpdate> statusHistory;

  /// Builds an incident from a Firestore document.
  /// [id] is the document id; [map] is the document's data.
  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final history = (map['statusHistory'] as List<dynamic>? ?? [])
        .map((entry) => StatusUpdate.fromMap(entry as Map<String, dynamic>))
        .toList();

    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromString(map['category'] as String?),
      status: IncidentStatus.fromString(map['status'] as String?),
      location: map['location'] as String? ?? '',
      imageUrls: List<String>.from(map['imageUrls'] as List<dynamic>? ?? []),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory: history,
    );
  }

  /// Converts the incident to a map for saving in Firestore.
  /// The id is not included because it is the document id.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'location': location,
      'imageUrls': imageUrls,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusHistory': statusHistory.map((entry) => entry.toMap()).toList(),
    };
  }
}