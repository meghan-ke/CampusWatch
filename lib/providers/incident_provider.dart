// lib/providers/incident_provider.dart
// Holds the incident STATE: the live list of reports, the search/filter
// settings, and whether a submit is in progress. Screens read this and
// rebuild automatically when it changes.
//
// It is linked to the signed-in user in app.dart (bindUser): it starts
// listening to Firestore at login and stops at logout.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../services/storage_service.dart';

class IncidentProvider extends ChangeNotifier {
  IncidentProvider({
    IncidentService? incidentService,
    StorageService? storageService,
  })  : _incidentService = incidentService ?? IncidentService(),
        _storageService = storageService ?? StorageService();

  final IncidentService _incidentService;
  final StorageService _storageService;

  AppUser? _user;
  StreamSubscription<List<Incident>>? _subscription;

  List<Incident> _all = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Search and filter settings (applied on the device; fine for campus scale).
  String _searchQuery = '';
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;

  // --- Read-only values for the UI -----------------------------------------

  /// Every incident, unfiltered (used for dashboard counts).
  List<Incident> get allIncidents => _all;

  /// Incidents after search and filters are applied. Newest first.
  List<Incident> get incidents {
    final query = _searchQuery.trim().toLowerCase();
    return _all.where((incident) {
      if (_statusFilter != null && incident.status != _statusFilter) {
        return false;
      }
      if (_categoryFilter != null && incident.category != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return incident.title.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.location.toLowerCase().contains(query);
    }).toList();
  }

  /// Only the signed-in user's own reports.
  List<Incident> get myIncidents =>
      _all.where((incident) => incident.reporterId == _user?.uid).toList();

  int countByStatus(IncidentStatus status, {List<Incident>? from}) =>
      (from ?? _all).where((incident) => incident.status == status).length;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != null ||
      _categoryFilter != null;

  // --- Linking to the signed-in user ----------------------------------------

  /// Called from app.dart whenever the sign-in state changes.
  /// Starts or stops the live Firestore listener.
  void bindUser(AppUser? user) {
    if (user?.uid == _user?.uid) {
      _user = user; // same person; keep listening
      return;
    }

    _subscription?.cancel();
    _subscription = null;
    _user = user;
    _all = const [];
    _errorMessage = null;
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;

    if (user == null) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    _subscription = _incidentService.watchIncidents().listen(
      (list) {
        _all = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Could not load reports. Check your connection.';
        notifyListeners();
      },
    );
  }

  // --- Search and filters ----------------------------------------------------

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(IncidentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  // --- Actions ---------------------------------------------------------------

  /// Uploads the photos (if any), then saves the report.
  /// Returns true on success; on failure see [errorMessage].
  Future<bool> submitReport({
    required String title,
    required String description,
    required String location,
    required IncidentCategory category,
    required List<XFile> images,
  }) async {
    final user = _user;
    if (user == null) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The id comes first because photos are stored under it.
      final id = _incidentService.newId();
      final urls = images.isEmpty
          ? <String>[]
          : await _storageService.uploadIncidentImages(
              incidentId: id,
              images: images,
            );

      final now = DateTime.now();
      await _incidentService.createIncident(
        Incident(
          id: id,
          title: title.trim(),
          description: description.trim(),
          category: category,
          status: IncidentStatus.submitted,
          location: location.trim(),
          imageUrls: urls,
          reporterId: user.uid,
          reporterName: user.name,
          createdAt: now,
          updatedAt: now,
          // The history always starts with "Submitted".
          statusHistory: [
            StatusUpdate(
              status: IncidentStatus.submitted,
              note: 'Report submitted',
              changedBy: user.name,
              changedAt: now,
            ),
          ],
        ),
      )
        // Firestore can wait forever when the network is unreachable.
          .timeout(const Duration(seconds: 20));
      return true;
      } on TimeoutException {
      _errorMessage =
          'Could not reach the server. Check your internet and try again.';
      return false;
      } on ImageUploadException catch (e) {
      _errorMessage = e.message;
      return false;
      } on FirebaseException catch (e) {
        _errorMessage = 'Could not submit report: ${e.message ?? e.code}';
        return false;
      } catch (_) {
        _errorMessage = 'Could not submit report. Please try again.';
        return false;
      } finally {
        _isSubmitting = false;
        notifyListeners();
      }
  }

  /// Staff action: change a report's status and record it in the history.
  /// (Firestore rules enforce that only staff can do this.)
  Future<bool> updateStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    String note = '',
  }) async {
    final user = _user;
    if (user == null || !user.role.isStaff) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _incidentService.updateStatus(
        incidentId: incidentId,
        newStatus: newStatus,
        note: note,
        staffName: user.name,
      );
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Could not update status: ${e.message ?? e.code}';
      return false;
    } catch (_) {
      _errorMessage = 'Could not update status. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

    /// Students may delete their own report while it is still "Submitted";
  /// staff may delete any report. Firestore rules enforce the same limits.
  Future<bool> deleteIncident(Incident incident) async {
    final user = _user;
    if (user == null) return false;

    final isOwner = incident.reporterId == user.uid;
    final allowed = user.role.isStaff ||
        (isOwner && incident.status == IncidentStatus.submitted);
    if (!allowed) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _incidentService.deleteIncident(incident.id);
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Could not delete report: ${e.message ?? e.code}';
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete report. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}