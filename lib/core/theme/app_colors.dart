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

  // Examination screen.
  static const Color examHeader = Color(0xFF095C37);
  static const Color examHeaderSubtitle = Color(0xFFD7F7E6);
  static const Color mushafBackground = Color(0xFFF7F4EA);
  static const Color mushafPage = Color(0xFFFFFDF6);
  static const Color mushafBorder = Color(0xFFB68933);
  static const Color mushafOutline = Color(0xFFD9B867);
  static const Color mushafInnerBorder = Color(0xFFC8A34D);
  static const Color mushafCorner = Color(0xFFA87E2B);
  static const Color mushafPageNumber = Color(0xFF8C671B);
  static const Color mushafFooterLine = Color(0x66DFCC99);
  static const List<Color> recordButtonGradient = [
    Color(0xFF095C37),
    Color(0xFF128D57),
  ];
  static const Color recordButtonGlow = Color(0x33128D57);
  static const Color recordButtonShadow = Color(0x4D0C7345);

  // Theory questions screen.
  static const Color questionsAction = Color(0xFF0D6E66);
  static const Color questionsActionShadow = Color(0x330D6E66);
  static const Color questionPromptBackground = Color(0xBFF9FAFB);
  static const Color optionBorder = Color(0xE6E5E7EB);
  static const Color optionMarkBorder = Color(0xFFD1D5DB);
  static const Color optionSelectedBackground = Color(0xFFEEF7F4);
  static const Color optionSelectedBorder = Color(0xFF3DB89C);
  static const Color optionSelectedMark = Color(0xFF1DA584);
  static const Color optionSelectedText = Color(0xFF0F766E);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBackground = Color(0xB3FEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
}
