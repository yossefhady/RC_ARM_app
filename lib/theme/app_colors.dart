import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds (slate scale)
  static const background  = Color(0xFFFBFCFD); // slate-25 — app chrome
  static const surface     = Color(0xFFFFFFFF); // slate-0  — cards / panels
  static const surfaceDeep = Color(0xFFF6F8FA); // slate-50 — sunken / stripe

  // Borders
  static const border      = Color(0xFFE3E7EC); // slate-150
  static const borderStrong= Color(0xFFD4D9E0); // slate-200

  // Text
  static const textPrimary = Color(0xFF262B36); // slate-800
  static const textMuted   = Color(0xFF6B7584); // slate-500
  static const textTertiary= Color(0xFF8A93A1); // slate-400

  // Accent — Techno Genius green
  static const accent       = Color(0xFF2E9E5A); // green-500 (brand primary)
  static const accentHover  = Color(0xFF24834A); // green-600
  static const accentActive = Color(0xFF1C6739); // green-700
  static const accentSoft   = Color(0xFFEBF7F0); // green-50
  static const accentDim    = Color(0x222E9E5A); // green-500 @ ~13% opacity

  // Semantic
  static const error        = Color(0xFFC4321A); // danger
  static const errorBg      = Color(0xFFFDECE8);
  static const info         = Color(0xFF1F6FCB); // info blue
  static const infoBg       = Color(0xFFE8F1FC);
  static const warning      = Color(0xFFC77A08);
  static const warningBg    = Color(0xFFFEF5E7);

  // Brand
  static const navy         = Color(0xFF1E2A3C); // navy-900 — headings
  static const orange       = Color(0xFFFF8C42); // orange-400 — mascot / brand warm
}
