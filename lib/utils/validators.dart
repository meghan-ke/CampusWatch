// lib/utils/validators.dart
// Form validation rules, shared by the login, register and report forms.
//
// Each validator receives what the user typed and returns:
//   - an error message (String) if the input is not acceptable, or
//   - null if the input is fine.
// This is exactly what a TextFormField's `validator:` parameter expects.

import 'constants.dart';

class Validators {
  Validators._();

  /// Text must not be empty. [fieldName] is used in the message.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // Simple check: something@something.something
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

    /// Registration only: a valid email that also belongs to an ALU domain.
  static String? aluEmail(String? value) {
    final basic = email(value);
    if (basic != null) return basic;

    final domain = value!.trim().toLowerCase().split('@').last;
    if (!AppConstants.allowedEmailDomains.contains(domain)) {
      return 'Use your ALU email (@alustudent.com or @alueducation.com)';
    }
    return null;
  }

  /// Firebase Authentication requires at least 6 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Used on the register screen. [original] is the first password field.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? name(String? value) {
    final missing = required(value, 'Name');
    if (missing != null) return missing;
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? incidentTitle(String? value) {
    final missing = required(value, 'Title');
    if (missing != null) return missing;
    if (value!.trim().length > AppConstants.titleMaxLength) {
      return 'Title must be at most ${AppConstants.titleMaxLength} characters';
    }
    return null;
  }

  static String? incidentDescription(String? value) {
    final missing = required(value, 'Description');
    if (missing != null) return missing;
    if (value!.trim().length < 10) {
      return 'Please describe the problem in at least 10 characters';
    }
    if (value.trim().length > AppConstants.descriptionMaxLength) {
      return 'Description must be at most '
          '${AppConstants.descriptionMaxLength} characters';
    }
    return null;
  }

  static String? location(String? value) => required(value, 'Location');
}