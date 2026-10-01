import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/course.dart';
import '../state/course_details_cubit.dart';

class CourseDetailsPage extends StatelessWidget {
  const CourseDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        shape: const Border(),
        leading: const AppBackButton(),
        title: const Text('تفاصيل الدورة'),
      ),
      body: BlocBuilder<CourseDetailsCubit, CourseDetailsState>(
        builder: (context, state) {
          return switch (state) {
            CourseDetailsLoading() => const AppLoadingView(),
            CourseDetailsError(:final message) => AppMessageView(
              message: message,
              onRetry: context.read<CourseDetailsCubit>().load,
            ),
            CourseDetailsLoaded(:final course, :final ruleNames) =>
              _CourseDetails(course: course, ruleNames: ruleNames),
          };
        },
      ),
    );
  }
}

class _CourseDetails extends StatelessWidget {
  const _CourseDetails({required this.course, required this.ruleNames});

  final Course course;
  final List<String> ruleNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _HeaderCard(course: course),
              if (course.objectives.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('أهداف الدورة'),
                const SizedBox(height: 12),
                for (final objective in course.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Objective(objective),
                  ),
              ],
              if (ruleNames.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('الأحكام الرئيسية'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final name in ruleNames) _RuleTag(name)],
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'بدء الاختبار',
                // The examination flow is implemented in its own step.
                onPressed: () =>
                    showAppSnackBar(context, 'الاختبارات ستتوفر قريبًا.'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: AppTextStyles.cairo(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.title,
                    lineHeight: 24,
                  ),
                ),
                if (course.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.description,
                    style: AppTextStyles.cairo(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.muted,
                      lineHeight: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4F2),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    course.level.label,
                    style: AppTextStyles.cairo(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF1A6B64),
                      lineHeight: 16.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF7F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5EBE8)),
            ),
            child: SvgPicture.asset(
              AppAssets.courseBookIcon,
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.title,
        lineHeight: 20,
      ),
    );
  }
}

class _Objective extends StatelessWidget {
  const _Objective(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1B6B64),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(AppAssets.checkIcon, width: 10, height: 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.cairo(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.bodyText,
              lineHeight: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleTag extends StatelessWidget {
  const _RuleTag(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        name,
        style: AppTextStyles.cairo(
          size: 12,
          weight: FontWeight.w500,
          color: AppColors.tagText,
          lineHeight: 16,
        ),
      ),
    );
  }
}
