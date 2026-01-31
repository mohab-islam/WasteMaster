import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors extracted from design (Eco-Warrior Dark Theme)
  static const Color background = Color(0xFF1E1C15); // Dark Earthy Brown/Black
  static const Color cardColor = Color(0xFF333022); // Dark Olive/Brown for cards
  static const Color primaryGold = Color(0xFFD4AF37); // Metallic Gold
  static const Color secondaryGreen = Color(0xFF558B2F); // Earthy Green accent
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textDim = Color(0xFFDDD0A4); // Beige/Gold for subtitles

  static ThemeData get darkTheme { 
    return ThemeData(
      brightness: Brightness.dark, // Switched to Dark
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
        unselectedItemColor: textDim.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.bold, fontSize: 22),
        bodyLarge: GoogleFonts.outfit(color: textLight),
        bodyMedium: GoogleFonts.outfit(color: textDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold, // Gold buttons
          foregroundColor: const Color(0xFF1E1C15), // Dark text on gold button for contrast
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor, // Inputs match card background
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
