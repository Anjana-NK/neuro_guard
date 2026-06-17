import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicTheme {
  // Brand Colors
  static const Color primaryBackground = Color(0xFF383B46); // Muted dark charcoal blue-gray
  static const Color cardForeground = Color(0xFFDCDCDC);    // Muted Light Gray
  
  // Cosmic Gradient Colors
  static const Color gradientTop = Color(0xFF0F2027);    // Blue-Black Dark Slate
  static const Color gradientMid = Color(0xFF203A43);    // Deep Sea Ocean Blue
  static const Color gradientBottom = Color(0xFF2C5364); // Slate Green Grey

  // Accent Colors
  static const Color accentAmber = Color(0xFFFFB300); // Amber for AI notifications/warnings
  static const Color accentTeal = Color(0xFF00BFA5);  // Vibrant Teal

  static LinearGradient get cosmicGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      gradientTop,
      gradientMid,
      gradientBottom,
    ],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentTeal,
        secondary: accentAmber,
        background: primaryBackground,
        surface: cardForeground,
        onBackground: Colors.white,
        onSurface: Colors.black87,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.italiana(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.italiana(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.italiana(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'serif',
          color: Colors.white70,
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'serif',
          color: Colors.white60,
          fontSize: 14,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'serif',
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardForeground,
        hintStyle: const TextStyle(color: Colors.black45, fontFamily: 'serif'),
        labelStyle: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardForeground,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
