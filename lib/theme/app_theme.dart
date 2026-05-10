import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Primary Brand Colors ───────────────────────────────────────────────────
  static const Color primaryColor = Color(
    0xFF314E7D,
  ); // Navy blue (home screen standard)
  static const Color primaryDark = Color(
    0xFF1E3A8A,
  ); // Darker navy (headers/buttons)
  static const Color secondaryColor = Color(
    0xFFF8FAFC,
  ); // Light gray background
  static const Color accentColor = Color(
    0xFF3B82F6,
  ); // Bright blue (links/focus)
  static const Color successColor = Color(0xFF22C55E); // Green
  static const Color warningColor = Color(0xFFFBBF24); // Amber/Yellow
  static const Color errorColor = Color(0xFFEF4444); // Red

  // ── Surface & Background ──────────────────────────────────────────────────
  static const Color surfaceColor = Colors.white;
  static const Color scaffoldBgColor = Color(
    0xFFF3F4F6,
  ); // grey[100] – home screen body
  static const Color cardBgColor = Colors.white;
  static const Color dividerColor = Color(0xFFE5E7EB); // grey[200]

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textColor = Color(0xFF1F2937); // Dark gray – primary text
  static const Color textDarkColor = Color(
    0xFF2C3E50,
  ); // Darker text (headings on cards)
  static const Color textLightColor = Color(
    0xFF6B7280,
  ); // Medium gray – secondary text
  static const Color textMutedColor = Color(0xFF9CA3AF); // Muted/hint text
  static const Color textOnPrimary = Colors.white; // Text on primary bg

  // ── Font Family (home screen uses 'outfit' throughout) ────────────────────
  static const String fontFamily = 'outfit';

  // ── Font Sizes (scaled from home screen usage) ────────────────────────────
  static const double fontXS = 10.0; // chips, badges
  static const double fontSM = 12.0; // captions, small labels
  static const double fontBase = 14.0; // body text, inputs
  static const double fontMD = 16.0; // section headers, button labels
  static const double fontLG = 18.0; // card titles, screen sub-headers
  static const double fontXL = 20.0; // price display
  static const double font2XL = 24.0; // large price / amount
  static const double font3XL = 28.0; // display
  static const double font4XL = 32.0; // hero text

  // ── Border Radii ──────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 999.0;

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    hintColor: accentColor,
    scaffoldBackgroundColor: scaffoldBgColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: textColor,
      onSurface: textColor,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textLightColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: primaryColor),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: GoogleFonts.outfit(fontSize: 14, color: textLightColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
    ),
  );
}
