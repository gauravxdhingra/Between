import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

TextTheme appTextTheme() {
  return TextTheme(
    // Hero amounts — 40sp bold
    displayLarge: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
      letterSpacing: -1.5,
    ),
    // Screen headings — 28sp semibold
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.5,
    ),
    // Section headings — 20sp semibold
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    // Card titles
    titleLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: kTextPrimary,
    ),
    // Body — 16sp regular
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: kTextPrimary,
    ),
    // Secondary — 14sp medium
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: kTextSecondary,
    ),
    // Tiny labels — 12sp medium
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: kTextMuted,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: kTextMuted,
      letterSpacing: 0.3,
    ),
  );
}

// Monospace amount text — used for all ₹ figures
TextStyle amountStyle({double size = 32, Color? color}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color ?? kTextPrimary,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
