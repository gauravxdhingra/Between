import 'package:flutter/material.dart';

import 'colors.dart';

const _inter = 'Inter';

TextTheme appTextTheme() {
  return const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
      letterSpacing: -1.5,
    ),
    headlineLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontFamily: _inter,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: _inter,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: kTextPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: kTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: _inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: kTextSecondary,
    ),
    bodySmall: TextStyle(
      fontFamily: _inter,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: kTextMuted,
    ),
    labelLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: _inter,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: kTextMuted,
      letterSpacing: 0.3,
    ),
  );
}

TextStyle amountStyle({double size = 32, Color? color}) {
  return TextStyle(
    fontFamily: _inter,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color ?? kTextPrimary,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
