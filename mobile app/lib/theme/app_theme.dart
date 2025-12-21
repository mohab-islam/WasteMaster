import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors extracted from design
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color cardColor = Color(0xFFF0F7F4); // Very light minty grey
  static const Color primaryGold = Color(0xFF26A69A); // Mint Green (Teal 400)
  static const Color secondaryGreen = Color(0xFF80CBC4); // Lighter Mint
  static const Color textLight = Color(0xFF212121); // Dark Grey/Black for Light Mode
  static const Color textDim = Color(0xFF757575); // Grey for subtitles

  static ThemeData get darkTheme { // keeping name 'darkTheme' but implementation is now Light/Mint
    return ThemeData(
      brightness: Brightness.light,
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
          backgroundColor: primaryGold,
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardColor: cardColor,
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
