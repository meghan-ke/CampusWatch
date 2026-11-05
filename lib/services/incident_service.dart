// lib/services/incident_service.dart
// Reads and writes incidents in Firestore (collection: incidents).
// This is the ONLY file that talks to that collection.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/incident.dart';
import '../utils/constants.dart';

class IncidentService {
  IncidentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(FirestorePaths.incidents);

  /// Creates a document id without saving anything yet.
  /// Needed first so photos can be uploaded into incident_images/{id}/.
  String newId() => _incidents.doc().id;

  /// Live list of all incidents, newest first. Emits again whenever any
  /// incident changes, so every screen stays up to date automatically.
  Stream<List<Incident>> watchIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Incident.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Saves a new incident using the id it already carries.
  Future<void> createIncident(Incident incident) {
    return _incidents.doc(incident.id).set(incident.toMap());
  }

  /// Staff action: changes the status and appends an entry to the history.
  /// FieldValue.arrayUnion adds to the list without rewriting the old entries.
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required String note,
    required String staffName,
  }) {
    final entry = StatusUpdate(
      status: newStatus,
      note: note.trim(),
      changedBy: staffName,
      changedAt: DateTime.now(),
    );

    return _incidents.doc(incidentId).update({
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
      'statusHistory': FieldValue.arrayUnion([entry.toMap()]),
    });
  }
}