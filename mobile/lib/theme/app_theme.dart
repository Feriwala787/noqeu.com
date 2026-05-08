import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF6C63FF);
  static const _secondary = Color(0xFF03DAC6);
  static const _error = Color(0xFFCF6679);
  static const _surface = Color(0xFF1E1E2E);
  static const _background = Color(0xFF13131F);
  static const _onSurface = Color(0xFFE2E2F0);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          secondary: _secondary,
          error: _error,
          surface: _surface,
          onSurface: _onSurface,
        ),
        scaffoldBackgroundColor: _background,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: _onSurface),
          headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: _onSurface),
          headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: _onSurface),
          titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _onSurface),
          titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: _onSurface),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: _onSurface),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: Color(0xFFAAAAAA)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: _onSurface),
          iconTheme: const IconThemeData(color: _onSurface),
        ),
        cardTheme: CardTheme(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E2E42), width: 1),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: _primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E2E42)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E2E42)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          labelStyle: GoogleFonts.inter(color: const Color(0xFF888888)),
          hintStyle: GoogleFonts.inter(color: const Color(0xFF555555)),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF2E2E42), thickness: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _surface,
          contentTextStyle: GoogleFonts.inter(color: _onSurface),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2E2E42),
          labelStyle: GoogleFonts.inter(fontSize: 12, color: _onSurface),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}
