import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme appTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
    ),
    headlineLarge: GoogleFonts.dmSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: GoogleFonts.dmSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

TextStyle amountStyle({double size = 32}) {
  return GoogleFonts.dmMono(
    fontSize: size,
    fontWeight: FontWeight.w700,
  );
}
