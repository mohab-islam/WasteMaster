import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors extracted from design
  static const Color background = Color(0xFF222018); // Dark Olive/Brown
  static const Color cardColor = Color(0xFF2D2B22); // Slightly lighter for cards
  static const Color primaryGold = Color(0xFFD4B066); // Gold/Yellow for accents
  static const Color secondaryGreen = Color(0xFF7DA77E); // Sage green for success/badges
  static const Color textLight = Color(0xFFF3F0E6); // Off-white text
  static const Color textDim = Color(0xFFA6A498); // Dimmed text for subtitles

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryGold,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primaryGold,
        unselectedItemColor: textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.bold, fontSize: 22),
        bodyLarge: GoogleFonts.outfit(color: textLight),
        bodyMedium: GoogleFonts.outfit(color: textDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: background, // Black text on Gold button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardColor: cardColor,
      /* cardTheme caused compilation issue on some versions, using property instead */
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.outfit(color: textDim),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
