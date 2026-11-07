// lib/utils/constants.dart
// App-wide constants. Keeping them here avoids "magic strings" scattered
// across the code: if a name changes, we change it in one place only.

class AppConstants {
  AppConstants._(); // Not meant to be instantiated; only holds constants.

  static const String appName = 'CampusWatch';

  /// Maximum number of photos a student can attach to one report.
  static const int maxImagesPerReport = 3;

  /// Photos are compressed to this quality (0-100) before upload
  /// to save storage space and mobile data.
  static const int imageQuality = 70;

  /// Limits for the report form.
  static const int titleMaxLength = 80;
  static const int descriptionMaxLength = 500;

  static const List<String> allowedEmailDomains = [
    'alustudent.com',
    'alueducation.com',
  ];
}

/// Names of Firestore collections. See docs/FIREBASE_SCHEMA.md.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String incidents = 'incidents';
}

/// Folder names in Firebase Storage.
/// Folder names in Firebase Storage.
/// Cloudinary settings for photo uploads. The cloud name and an UNSIGNED
/// preset name are safe to ship in the app; never add the API secret here.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'txnykemd';
  static const String uploadPreset = 'campuswatch_unsigned';
}