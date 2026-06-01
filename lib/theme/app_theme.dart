import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette — Deep space / HPC aesthetic
  static const Color primary = Color(0xFF00E5FF);       // Cyan accent
  static const Color secondary = Color(0xFF7C4DFF);     // Purple
  static const Color success = Color(0xFF00E676);       // Green
  static const Color warning = Color(0xFFFFD740);       // Amber
  static const Color error = Color(0xFFFF5252);         // Red
  static const Color bgDark = Color(0xFF0A0E1A);        // Deep navy
  static const Color bgCard = Color(0xFF111827);        // Card bg
  static const Color bgCardLight = Color(0xFF1C2333);   // Lighter card
  static const Color textPrimary = Color(0xFFECF0F1);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color divider = Color(0xFF1E2D3D);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: bgCard,
      error: error,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.orbitron(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      headlineMedium: GoogleFonts.orbitron(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        color: textSecondary,
        fontSize: 13,
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: divider, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      titleTextStyle: GoogleFonts.orbitron(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: textSecondary,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 2),
      ),
      labelStyle: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: bgDark,
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerTheme: const DividerThemeData(color: divider),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0077CC),
      secondary: secondary,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDDE3EE), width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.orbitron(
        color: const Color(0xFF0D1117),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
