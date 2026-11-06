// lib/models/app_user.dart
// Describes one registered person. Stored in Firestore at users/{uid}.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Same id as the Firebase Authentication account.
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  /// Builds a user from a Firestore document.
  /// [uid] is the document id; [map] is the document's data.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the user to a map for saving in Firestore.
  /// The uid is not included because it is the document id.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}