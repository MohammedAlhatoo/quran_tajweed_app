import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/course.dart';
import 'course_level_style.dart';

/// A course row on the courses list.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = CourseLevelStyle.of(course.level);
    final radius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: style.badgeBackground,
                    borderRadius: radius,
                    border: Border.all(color: style.badgeBorder),
                  ),
                  child: SvgPicture.asset(
                    AppAssets.levelIcon(course.level.value),
                    width: 28,
                    height: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cairo(
                          size: 16,
                          weight: FontWeight.w700,
                          color: AppColors.title,
                          lineHeight: 22,
                        ),
                      ),
                      if (course.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          course.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cairo(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
                            lineHeight: 18,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                        decoration: BoxDecoration(
                          color: style.chipBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.level.label,
                          style: AppTextStyles.cairo(
                            size: 11,
                            weight: FontWeight.w600,
                            color: style.chipText,
                            lineHeight: 16.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(AppAssets.chevronIcon, width: 20, height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
