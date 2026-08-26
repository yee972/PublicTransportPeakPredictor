import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DemandBand { quiet, baseline, moderate, busy, unknown }

class DemandPalette {
  static const Color quiet = Color(0xFF6BBF8A);
  static const Color baseline = Color(0xFF2E9E63);
  static const Color moderate = Color(0xFFE8A33D);
  static const Color busy = Color(0xFFD94F45);
  static const Color unknown = Color(0xFF9CA3AF);

  static Color of(DemandBand band) {
    switch (band) {
      case DemandBand.quiet:
        return quiet;
      case DemandBand.baseline:
        return baseline;
      case DemandBand.moderate:
        return moderate;
      case DemandBand.busy:
        return busy;
      case DemandBand.unknown:
        return unknown;
    }
  }

  static String label(DemandBand band) {
    switch (band) {
      case DemandBand.quiet:
        return 'Quieter than usual';
      case DemandBand.baseline:
        return 'Typical volume';
      case DemandBand.moderate:
        return 'Busier than usual';
      case DemandBand.busy:
        return 'Significantly busier';
      case DemandBand.unknown:
        return 'Not enough data';
    }
  }

  static String shortLabel(DemandBand band) {
    switch (band) {
      case DemandBand.quiet:
        return 'QUIET';
      case DemandBand.baseline:
        return 'BASELINE FLOW';
      case DemandBand.moderate:
        return 'MODERATE FLOW';
      case DemandBand.busy:
        return 'PEAK FLOW';
      case DemandBand.unknown:
        return 'NO DATA';
    }
  }
}

class AppTheme {
  static const Color primary = Color(0xFF0E7A46);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF6F7F9);
  static const Color outline = Color(0xFFE3E6EA);
  static const Color textPrimary = Color(0xFF14181F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color info = Color(0xFFE8F0FE);

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      surface: surface,
      outlineVariant: outline,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textPrimary),
        bodySmall: GoogleFonts.inter(fontSize: 12.5, color: textSecondary),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.robotoMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? primary : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : textSecondary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: outline, space: 1, thickness: 1),
    );
  }

  static TextStyle mono({
    double size = 13,
    Color color = textPrimary,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.robotoMono(fontSize: size, color: color, fontWeight: weight);
  }
}
