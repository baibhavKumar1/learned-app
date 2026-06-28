import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // =========================================================
  // 🎨 COLOR PALETTES - Uncomment the one you want to use!
  // =========================================================

  // --- 1. Ethereal Tech (Current - Smooth Indigo & Violet) ---
  // static const Color lightPrimary = Color(0xFF6366F1);
  // static const Color lightSecondary = Color(0xFF14B8A6);
  // static const Color lightBackground = Color(0xFFF8FAFC);
  // static const Color lightSurface = Colors.white;
  // static const Color lightTextPrimary = Color(0xFF0F172A);
  // static const Color lightTextSecondary = Color(0xFF64748B);
  
  // static const Color darkPrimary = Color(0xFF8B5CF6);
  // static const Color darkSecondary = Color(0xFF2DD4BF);
  // static const Color darkBackground = Color(0xFF09090B); // True Black feel
  // static const Color darkSurface = Color(0xFF18181B);
  // static const Color darkTextPrimary = Color(0xFFFAFAFA);
  // static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // --- 3. Clean Monochrome (Sleek High Contrast Black/White) ---
  static const Color lightPrimary = Color(0xFF000000);
  static const Color lightSecondary = Color(0xFF52525B);
  static const Color lightBackground = Color(0xFFF4F4F5);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  
  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color darkSecondary = Color(0xFFA1A1AA);
  static const Color darkBackground = Color(0xFF000000); // Pitch Black
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

  // --- 4. Forest Emerald (Calm, Focus-oriented Greens) ---
  // static const Color lightPrimary = Color(0xFF059669);
  // static const Color lightSecondary = Color(0xFF0D9488);
  // static const Color lightBackground = Color(0xFFF0FDF4);
  // static const Color lightSurface = Colors.white;
  // static const Color lightTextPrimary = Color(0xFF064E3B);
  // static const Color lightTextSecondary = Color(0xFF34D399);
  
  // static const Color darkPrimary = Color(0xFF10B981);
  // static const Color darkSecondary = Color(0xFF14B8A6);
  // static const Color darkBackground = Color(0xFF022C22); // Deep Forest Black
  // static const Color darkSurface = Color(0xFF064E3B);
  // static const Color darkTextPrimary = Color(0xFFECFDF5);
  // static const Color darkTextSecondary = Color(0xFF6EE7B7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        outline: Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightTextPrimary),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightTextPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: lightTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0, // Flat design for abstract feel
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: darkTextPrimary,
        outline: Color(0xFF27272A), // Zinc 800
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkTextPrimary),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTextPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: darkTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: Color(0xFF27272A), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
      ),
    );
  }
}
