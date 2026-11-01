import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theme configuration for the Easy Rentals app.
///
/// Exposes the brand colour palette as static constants and builds the
/// app-wide [ThemeData] via [lightTheme]. Widgets should read colours from
/// here (e.g. `AppTheme.primaryPurple`) rather than hard-coding values.
class AppTheme {
  // Easy Rentals brand colours
  static const Color primaryPurple = Color(0xFF6428D9);
  static const Color darkPurple = Color(0xFF4520A8);
  static const Color brandOrange = Color(0xFFF4510B);
  static const Color brandGreen = Color(0xFF60B536);

  // Existing properties retained for compatibility
  static const Color background = Color(0xFFF8F7FB);
  static const Color cardColor = Colors.white;
  static const Color buttonColor = primaryPurple;
  static const Color textPrimary = Color(0xFF24202D);
  static const Color textSecondary = Color(0xFF777381);
  static const Color white = Colors.white;

  static const Color borderColor = Color(0xFFE8E4EF);
  static const Color successColor = brandGreen;
  static const Color highlightColor = brandOrange;

  /// Builds the app's light theme.
  ///
  /// Uses Material 3 with the Poppins font family across the text theme, and
  /// configures consistent styling for buttons, inputs, app bars, cards,
  /// chips, and the bottom navigation bar.
  static ThemeData get lightTheme {
    // Start from Google Fonts' Poppins text theme, then override specific
    // styles below.
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryPurple,

      // Seed the colour scheme from the brand purple, then pin the key roles
      // (primary/secondary/tertiary/surface) so they stay stable regardless
      // of any future Material 3 seed-colour algorithm changes.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.light,
        primary: primaryPurple,
        secondary: brandOrange,
        tertiary: brandGreen,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),

      // Typography scale. Each style is defined explicitly so the visual
      // hierarchy stays consistent across screens.
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),

      // Buttons

      // Filled buttons: solid purple, pill-shaped, flat elevation.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 24,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons: purple outline matching the filled variant's shape.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: const BorderSide(color: primaryPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 24,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons: purple text, semibold.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPurple,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields

      // Shared decoration for TextFields: filled white background, rounded
      // borders that highlight purple on focus and red on error.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryPurple,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),

      // App bars

      // Flat app bar that blends into the page background with a semibold
      // Poppins title, left-aligned by default.
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards

      // Border-only cards (no shadow) with 16px rounded corners.
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),

      // Selection controls

      // Pill-shaped chips: white when unselected, purple when selected.
      chipTheme: ChipThemeData(
        backgroundColor: white,
        selectedColor: primaryPurple,
        disabledColor: borderColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: const BorderSide(color: borderColor),
      ),

      // Bottom navigation defaults

      // Material 3 NavigationBar: purple-tinted indicator for the selected
      // item, with label colour/weight changing based on selection state.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        indicatorColor: primaryPurple.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? primaryPurple : textSecondary,
          );
        }),
      ),

      // Dividers and progress indicators use the brand colours.
      dividerColor: borderColor,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPurple,
      ),
    );
  }
}