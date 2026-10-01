import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The student's four-tab bottom bar. Tab order matches the shell branches.
class StudentBottomNav extends StatelessWidget {
  const StudentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<(String label, String icon)> _tabs = [
    ('الرئيسية', AppAssets.navHomeIcon),
    ('الدورات', AppAssets.navCoursesIcon),
    ('الاختبارات', AppAssets.navExamsIcon),
    ('الملف الشخصي', AppAssets.navProfileIcon),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
          child: Row(
            children: [
              for (final (index, (label, icon)) in _tabs.indexed)
                Expanded(
                  child: _Tab(
                    label: label,
                    icon: icon,
                    isActive: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.faint;

    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cairo(
                  size: 11,
                  weight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  lineHeight: 16.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
