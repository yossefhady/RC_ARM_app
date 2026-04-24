import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppText {
  static TextStyle mono({
    double fontSize = 12,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle label({
    double fontSize = 10,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textMuted,
    double letterSpacing = 0.22,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}
