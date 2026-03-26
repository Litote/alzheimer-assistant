import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Soft, reassuring palette — accessibility for seniors
  static const _primaryColor = Color(0xFF5B8DEF); // soft blue
  static const _backgroundColor = Color(0xFFF8F9FF); // slightly blue-tinted white
  static const _surfaceColor = Color(0xFFFFFFFF);
  static const _onPrimaryColor = Color(0xFFFFFFFF);
  static const _textColor = Color(0xFF1A1A2E);
  static const _subtleTextColor = Color(0xFF6B7280);

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: _onPrimaryColor,
      secondary: Color(0xFF7CB9E8),
      onSecondary: _onPrimaryColor,
      error: Color(0xFFE53E3E),
      onError: _onPrimaryColor,
      surface: _surfaceColor,
      onSurface: _textColor,
      surfaceContainerHighest: Color(0xFFEEF2FF),
      onSurfaceVariant: _subtleTextColor,
      outline: Color(0xFFD1D5DB),
    );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _textColor,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: _textColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _textColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _subtleTextColor,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _backgroundColor,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: _onPrimaryColor,
          shape: const CircleBorder(),
          elevation: 4,
        ),
      ),
    );
  }
}
