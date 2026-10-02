import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../student/presentation/widgets/user_avatar.dart';

/// A submitted examination on the supervisor's list.
class PendingExamCard extends StatelessWidget {
  const PendingExamCard({
    super.key,
    required this.exam,
    required this.student,
    required this.course,
    required this.onTap,
  });

  final Exam exam;

  /// Null when the student's account could not be read.
  final AppUser? student;

  /// Null when the course is no longer available.
  final Course? course;

  final VoidCallback onTap;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final submittedAt = exam.submittedAt;
    final details = [
      course?.name ?? 'دورة غير متاحة',
      if (submittedAt != null) _formatDate(submittedAt),
    ].join(' · ');

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
                const UserAvatar(size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student?.name ?? 'طالب غير معروف',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cairo(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          lineHeight: 20,
                        ),
                      ),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cairo(
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppColors.textHint,
                          lineHeight: 16.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SvgPicture.asset(AppAssets.chevronIcon, width: 16, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
