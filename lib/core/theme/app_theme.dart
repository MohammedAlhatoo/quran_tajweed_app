import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static const double radius = 12;

  static final BorderRadius _borderRadius = BorderRadius.circular(radius);

  static ThemeData get light {
    final shape = RoundedRectangleBorder(borderRadius: _borderRadius);

    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: _borderRadius,
      borderSide: BorderSide(color: color),
    );

    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTextStyles.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.header,
        foregroundColor: AppColors.onHeader,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.onHeader),
        actionsIconTheme: const IconThemeData(color: AppColors.onHeader),
        // Light status bar icons over the green bar.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.cairo(
          size: 17,
          weight: FontWeight.w700,
          color: AppColors.onHeader,
          lineHeight: 24,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.cairo(
          size: 17,
          weight: FontWeight.w700,
          color: AppColors.title,
          lineHeight: 26,
        ),
        contentTextStyle: AppTextStyles.cairo(
          size: 14,
          weight: FontWeight.w500,
          color: AppColors.bodyText,
          lineHeight: 22,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        textStyle: AppTextStyles.body,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
        contentTextStyle: AppTextStyles.cairo(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.onPrimary,
          lineHeight: 20,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: AppTextStyles.hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textStrong,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          shape: shape,
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),
    );
  }
}
