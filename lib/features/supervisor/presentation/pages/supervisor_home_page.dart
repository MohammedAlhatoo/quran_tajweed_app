import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/presentation/state/courses_cubit.dart';
import '../state/pending_exams_cubit.dart';
import '../widgets/pending_exam_card.dart';

/// The supervisor's home: the submitted examinations of the square that await
/// review, oldest first.
class SupervisorHomePage extends StatelessWidget {
  const SupervisorHomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final cubit = context.read<AuthCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final name = authState is AuthAuthenticated ? authState.user.name : '';
    final coursesState = context.watch<CoursesCubit>().state;
    final coursesById = <String, Course>{
      if (coursesState is CoursesLoaded)
        for (final course in coursesState.courses) course.id: course,
    };

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('مراجعة الاختبارات'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.muted),
          ),
        ],
      ),
      body: BlocBuilder<PendingExamsCubit, PendingExamsState>(
        builder: (context, state) {
          final reload = context.read<PendingExamsCubit>().load;

          return switch (state) {
            PendingExamsLoading() => const AppLoadingView(),
            PendingExamsError(:final message) => AppMessageView(
              message: message,
              onRetry: reload,
            ),
            PendingExamsLoaded(:final exams) when exams.isEmpty =>
              AppMessageView(
                message: 'لا توجد اختبارات بانتظار المراجعة.',
                onRetry: reload,
              ),
            PendingExamsLoaded(:final exams, :final students) =>
              RefreshIndicator(
                onRefresh: reload,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  // The summary comes first.
                  itemCount: exams.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _Summary(name: name, count: exams.length);
                    }
                    final exam = exams[index - 1];
                    return PendingExamCard(
                      exam: exam,
                      student: students[exam.studentId],
                      course: coursesById[exam.courseId],
                      onTap: () =>
                          context.push(RouteNames.supervisorExam(exam.id)),
                    );
                  },
                ),
              ),
          };
        },
      ),
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
