import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/role_shell.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../admin/presentation/state/report_cubit.dart';
import '../../../admin/presentation/widgets/report_view.dart';
import '../../../admin/presentation/widgets/square_report_pdf_button.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/presentation/state/courses_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/state/notifications_cubit.dart';
import '../state/pending_exams_cubit.dart';
import '../state/reviewed_exams_cubit.dart';
import '../widgets/review_exam_card.dart';

/// The supervisor's area: the examinations that need review, those already
/// reviewed, the square's report and the notifications.
class SupervisorHomePage extends StatelessWidget {
  const SupervisorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingState = context.watch<PendingExamsCubit>().state;
    final notificationsState = context.watch<NotificationsCubit>().state;

    return RoleShell(
      tabs: [
        RoleTab(
          label: 'المراجعة',
          icon: Icons.fact_check_outlined,
          title: 'اختبارات تحتاج مراجعة',
          // The counter comes from the examinations themselves.
          badge: pendingState is PendingExamsLoaded
              ? pendingState.exams.length
              : 0,
          onSelected: context.read<PendingExamsCubit>().load,
          body: const _PendingTab(),
        ),
        RoleTab(
          label: 'تمت المراجعة',
          icon: Icons.task_alt_rounded,
          title: 'اختبارات تمت مراجعتها',
          onSelected: context.read<ReviewedExamsCubit>().load,
          body: const _ReviewedTab(),
        ),
        RoleTab(
          label: 'التقارير',
          icon: Icons.bar_chart_rounded,
          title: 'تقرير المربع',
          onSelected: context.read<ReportCubit>().load,
          body: ReportView(
            header: (report) => SquareReportPdfButton(report: report),
          ),
        ),
        RoleTab(
          label: 'الإشعارات',
          icon: Icons.notifications_none_rounded,
          title: 'الإشعارات',
          badge: notificationsState is NotificationsLoaded
              ? notificationsState.unreadCount
              : 0,
          body: NotificationsView(
            onOpen: (notification) =>
                context.push(RouteNames.supervisorExam(notification.relatedId)),
          ),
        ),
      ],
    );
  }
}

Map<String, Course> _coursesById(BuildContext context) {
  final state = context.watch<CoursesCubit>().state;
  return {
    if (state is CoursesLoaded)
      for (final course in state.courses) course.id: course,
  };
}

class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final name = authState is AuthAuthenticated ? authState.user.name : '';
    final coursesById = _coursesById(context);

    return BlocBuilder<PendingExamsCubit, PendingExamsState>(
      builder: (context, state) {
        final reload = context.read<PendingExamsCubit>().load;

        return switch (state) {
          PendingExamsLoading() => const AppLoadingView(),
          PendingExamsError(:final message) => AppMessageView(
            message: message,
            onRetry: reload,
          ),
          PendingExamsLoaded(:final exams) when exams.isEmpty => AppMessageView(
            message: 'لا توجد اختبارات بانتظار المراجعة.',
            onRetry: reload,
          ),
          PendingExamsLoaded(:final exams, :final students) => RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // The summary comes first.
              itemCount: exams.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _Summary(name: name, count: exams.length);
                }
                final exam = exams[index - 1];
                return ReviewExamCard(
                  exam: exam,
                  student: students[exam.studentId],
                  course: coursesById[exam.courseId],
                  onTap: () => context.push(RouteNames.supervisorExam(exam.id)),
                );
              },
            ),
          ),
        };
      },
    );
  }
}

class _ReviewedTab extends StatelessWidget {
  const _ReviewedTab();

  @override
  Widget build(BuildContext context) {
    final coursesById = _coursesById(context);

    return BlocBuilder<ReviewedExamsCubit, ReviewedExamsState>(
      builder: (context, state) {
        final reload = context.read<ReviewedExamsCubit>().load;

        return switch (state) {
          ReviewedExamsLoading() => const AppLoadingView(),
          ReviewedExamsError(:final message) => AppMessageView(
            message: message,
            onRetry: reload,
          ),
          ReviewedExamsLoaded(:final exams) when exams.isEmpty =>
            AppMessageView(
              message: 'لا توجد اختبارات تمت مراجعتها بعد.',
              onRetry: reload,
            ),
          ReviewedExamsLoaded(
            :final exams,
            :final students,
            :final evaluations,
          ) =>
            RefreshIndicator(
              onRefresh: reload,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: exams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final exam = exams[index];
                  return ReviewExamCard(
                    exam: exam,
                    student: students[exam.studentId],
                    course: coursesById[exam.courseId],
                    evaluation: evaluations[exam.id],
                    onTap: () =>
                        context.push(RouteNames.supervisorExam(exam.id)),
                  );
                },
              ),
            ),
        };
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحبًا $name',
            style: AppTextStyles.cairo(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.title,
              lineHeight: 24,
            ),
          ),
          Text(
            'اختبارات بانتظار المراجعة: $count',
            style: AppTextStyles.cairo(
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.muted,
              lineHeight: 20,
            ),
          ),
        ],
      ),
    );
  }
}
