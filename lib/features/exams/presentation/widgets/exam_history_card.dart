import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/entities/course_level.dart';
import '../../../courses/presentation/widgets/course_level_style.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_status.dart';

/// An examination row on the exam history.
class ExamHistoryCard extends StatelessWidget {
  const ExamHistoryCard({
    super.key,
    required this.exam,
    required this.course,
    this.onTap,
  });

  final Exam exam;

  /// Null when the course is no longer available.
  final Course? course;

  /// Null when the examination has nothing to open.
  final VoidCallback? onTap;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final level = course?.level ?? CourseLevel.introductory;
    final style = CourseLevelStyle.of(level);
    final radius = BorderRadius.circular(16);
    final startedAt = exam.startedAt;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: style.historyBadgeBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: style.historyBadgeBorder),
                  ),
                  child: SvgPicture.asset(
                    AppAssets.historyLevelIcon(level.value),
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course?.name ?? 'دورة غير متاحة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cairo(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          lineHeight: 20,
                        ),
                      ),
                      if (startedAt != null)
                        Text(
                          _formatDate(startedAt),
                          style: AppTextStyles.cairo(
                            size: 11,
                            weight: FontWeight.w500,
                            color: AppColors.textHint,
                            lineHeight: 16.5,
                            letterSpacing: -0.275,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(exam.status),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  SvgPicture.asset(
                    AppAssets.chevronIcon,
                    width: 16,
                    height: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final ExamStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, border, text) = switch (status) {
      ExamStatus.approved => (
        const Color(0xFFE6F7F3),
        const Color(0xFFB3EBDD),
        const Color(0xFF00A884),
      ),
      _ when status.isAwaitingReview => (
        const Color(0xFFEFF6FF),
        const Color(0xFFBFDBFE),
        const Color(0xFF2563EB),
      ),
      _ => (
        const Color(0xFFEBF7F7),
        const Color(0xFFC2EBEB),
        const Color(0xFF149999),
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
        status.label,
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
