import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

enum StatusTone { success, info, neutral, danger }

/// A small coloured label for a status, in the style of the exam history.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, border, text) = switch (tone) {
      StatusTone.success => (
        const Color(0xFFE6F7F3),
        const Color(0xFFB3EBDD),
        const Color(0xFF00A884),
      ),
      StatusTone.info => (
        const Color(0xFFEFF6FF),
        const Color(0xFFBFDBFE),
        const Color(0xFF2563EB),
      ),
      StatusTone.neutral => (
        const Color(0xFFEBF7F7),
        const Color(0xFFC2EBEB),
        const Color(0xFF149999),
      ),
      StatusTone.danger => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFECACA),
        const Color(0xFFDC2626),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: AppTextStyles.cairo(
          size: 12,
          weight: FontWeight.w700,
          color: text,
          lineHeight: 16,
        ),
      ),
    );
  }
}
