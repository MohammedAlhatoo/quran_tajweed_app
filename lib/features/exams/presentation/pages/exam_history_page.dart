import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/presentation/state/courses_cubit.dart';
import '../../domain/entities/exam_status.dart';
import '../state/exam_history_cubit.dart';
import '../widgets/exam_history_card.dart';

/// The exams tab: the student's examinations, newest first.
class ExamHistoryPage extends StatelessWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final coursesState = context.watch<CoursesCubit>().state;
    final coursesById = <String, Course>{
      if (coursesState is CoursesLoaded)
        for (final course in coursesState.courses) course.id: course,
    };

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('سجل الاختبارات'),
      ),
      body: BlocBuilder<ExamHistoryCubit, ExamHistoryState>(
        builder: (context, state) {
          final reload = context.read<ExamHistoryCubit>().load;

          return switch (state) {
            ExamHistoryLoading() => const AppLoadingView(),
            ExamHistoryError(:final message) => AppMessageView(
              message: message,
              onRetry: reload,
            ),
            ExamHistoryLoaded(:final exams) when exams.isEmpty =>
              AppMessageView(message: 'لا توجد اختبارات بعد.', onRetry: reload),
            ExamHistoryLoaded(:final exams) => RefreshIndicator(
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
                  return ExamHistoryCard(
                    exam: exam,
                    course: coursesById[exam.courseId],
                    // An open examination is continued; an approved one shows
                    // its result. One awaiting review has nothing to open.
                    onTap: exam.status.isOpen
                        ? () => context.push(RouteNames.studentExam(exam.id))
                        : exam.status == ExamStatus.approved
                        ? () => context.push(
                            RouteNames.studentExamResult(exam.id),
                          )
                        : null,
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
