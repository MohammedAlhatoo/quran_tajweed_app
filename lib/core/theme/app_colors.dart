import 'package:flutter/material.dart';

/// Colors taken from the approved Figma design.
abstract final class AppColors {
  static const Color primary = Color(0xFF0F8A5F);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSoft = Color(0xFFF9FBFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xB3F8FAFC);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textStrong = Color(0xFF334155);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Signed-in screens.
  static const Color pageBackground = Color(0xFFF8FAFC);
  static const Color ink = Color(0xFF111827);
  static const Color title = Color(0xFF1F2937);
  static const Color bodyText = Color(0xFF374151);
  static const Color tagText = Color(0xFF4B5563);
  static const Color muted = Color(0xFF6B7280);
  static const Color faint = Color(0xFF9CA3AF);
  static const Color line = Color(0xFFE5E7EB);
  static const Color lineSoft = Color(0xFFF3F4F6);
  static const Color cardBorder = Color(0xFFECEFF1);

  static const List<Color> heroGradient = [
    Color(0xFF173A34),
    Color(0xFF1E4D45),
    Color(0xFF122B27),
  ];
  static const Color heroSubtitle = Color(0xE6D1FAE5);

  static const Color avatarBackground = Color(0xFF1B4D3E);
  static const Color avatarBorder = Color(0x330D9488);
  static const Color iconTileBackground = Color(0xFFF0FDFA);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBackground = Color(0xB3FEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
}
