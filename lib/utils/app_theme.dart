// lib/utils/app_theme.dart
// The app's colors and visual style, defined once so every screen matches.
// app.dart passes AppTheme.light to MaterialApp.
//
// Palette: deep burgundy (primary) and dusty rose (secondary).
// To re-theme the whole app, change the two brand colors in AppColors.

import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Named colors used across the app.
class AppColors {
  AppColors._();

  // --- Brand palette -----------------------------------------------------------
  /// Deep burgundy: app bar, buttons, banner, icons, active tab.
  static const Color primary = Color(0xFF7D0C44);

  /// Dusty rose: soft accents such as selected chips and tab highlights.
  /// Used as a tint, not as a background for white text.
  static const Color secondary = Color(0xFFA9627B);

  // --- Neutrals and feedback -----------------------------------------------------
  static const Color background = Color(0xFFFAF5F7); // Faint rose-tinted white
  static const Color error = Color(0xFFD32F2F);

  /// One color per status, used by the status chip and the timeline.
  /// Keeping the mapping here means both always agree.
  /// These stay non-burgundy on purpose, so statuses never blend into the
  /// brand color.
  static Color forStatus(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.submitted:
        return const Color(0xFF757575); // Grey: waiting
      case IncidentStatus.underReview:
        return const Color(0xFFF9A825); // Amber: being looked at
      case IncidentStatus.inProgress:
        return const Color(0xFF1E88E5); // Blue: work started
      case IncidentStatus.resolved:
        return const Color(0xFF2E7D32); // Green: done
    }
  }
}

/// The overall Material theme for the app.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    // Build the scheme from the brand color, then pin the main colors so
    // Material does not shift them to a different shade.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      error: AppColors.error,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      // Material 3 tints surfaces with the seed color, which caused the
      // washed-out pink bars. Transparent switches that tint off.
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,

      // Top bar on every screen: burgundy with white text.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Look of every text input in the app.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Look of every ElevatedButton in the app.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Outlined buttons (Gallery, Camera, Logout).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text buttons such as "Register" and "See all".
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // The "Report" button above the navigation bar.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // Bottom navigation bar: white, with a dusty-rose highlight behind the
      // selected tab and a burgundy icon and label.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.secondary.withOpacity(0.28),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.grey.shade700,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.grey.shade700,
          );
        }),
      ),

      // Selected filter and category chips: soft rose with a burgundy tick.
      chipTheme: ChipThemeData(
        selectedColor: AppColors.secondary.withOpacity(0.28),
        checkmarkColor: AppColors.primary,
        side: BorderSide(color: Colors.grey.shade300),
      ),

      // Bottom sheets (the staff "Update status" sheet).
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}