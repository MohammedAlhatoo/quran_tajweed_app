import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/presentation/state/courses_cubit.dart';
import '../../../courses/presentation/widgets/course_level_style.dart';
import '../../../notifications/presentation/state/notifications_cubit.dart';
import '../../../student/presentation/widgets/user_avatar.dart';

/// The student's home tab.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<CoursesCubit>().load,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _HeroBanner(
                    onTap: () => context.go(RouteNames.studentCourses),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'الدورات المتاحة',
                    style: AppTextStyles.cairo(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.title,
                      lineHeight: 20,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _CoursesGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final name = authState is AuthAuthenticated ? authState.user.name : '';
    final firstName = name.trim().split(' ').first;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              const UserAvatar(size: 44, iconSize: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبًا $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairo(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                        lineHeight: 20,
                      ),
                    ),
                    Text(
                      'استمر في رحلتك نحو إتقان القرآن',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairo(
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                        lineHeight: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _NotificationsButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    final unread = state is NotificationsLoaded ? state.unreadCount : 0;

    return Semantics(
      button: true,
      label: 'الإشعارات',
      child: Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.danger,
        child: Material(
          color: const Color(0xFFF9FAFB),
          shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(RouteNames.studentNotifications),
            child: SizedBox.square(
              dimension: 36,
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.bellIcon,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: AppColors.heroGradient,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ابدأ اختبارك الآن',
                        style: AppTextStyles.cairo(
                          size: 16,
                          weight: FontWeight.w700,
                          color: AppColors.onPrimary,
                          lineHeight: 24,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختر الدورة المناسبة لك',
                        style: AppTextStyles.cairo(
                          size: 12,
                          weight: FontWeight.w400,
                          color: AppColors.heroSubtitle,
                          lineHeight: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: SvgPicture.asset(
                    AppAssets.homeHeroBookIcon,
                    width: 40,
                    height: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  const _CoursesGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoursesCubit, CoursesState>(
      builder: (context, state) {
        final reload = context.read<CoursesCubit>().load;

        return switch (state) {
          CoursesLoading() => const AppLoadingView(),
          CoursesError(:final message) => AppMessageView(
            message: message,
            onRetry: reload,
          ),
          CoursesLoaded(:final courses) when courses.isEmpty => AppMessageView(
            message: 'لا توجد دورات متاحة حاليًا.',
            onRetry: reload,
          ),
          CoursesLoaded(:final courses) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 112,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) => _CourseTile(courses[index]),
          ),
        };
      },
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile(this.course);

  final Course course;

  @override
  Widget build(BuildContext context) {
    final style = CourseLevelStyle.of(course.level);
    final radius = BorderRadius.circular(16);

    return Material(
      color: style.homeCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: style.homeCardBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.push(RouteNames.studentCourseDetails(course.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  AppAssets.homeLevelIcon(course.level.value),
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.cairo(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.title,
                  lineHeight: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
