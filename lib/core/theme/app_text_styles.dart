import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles taken from the approved Figma design (Cairo).
abstract final class AppTextStyles {
  static TextStyle get heading => GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static TextStyle get button => GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
  );

  static TextStyle get buttonSecondary => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
  );

  static TextStyle get body => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get hint => body.copyWith(color: AppColors.textHint);

  static TextStyle get subtitle => GoogleFonts.cairo(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 19.5 / 13,
    letterSpacing: 0.325,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  static TextTheme get textTheme =>
      GoogleFonts.cairoTextTheme()
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            headlineSmall: heading,
            bodyMedium: body,
            bodySmall: subtitle,
            labelLarge: buttonSecondary,
            labelSmall: caption,
          );
}
