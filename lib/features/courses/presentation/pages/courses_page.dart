import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../state/courses_cubit.dart';
import '../widgets/course_card.dart';

/// The courses tab: the list of active courses.
class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الدورات'),
      ),
      body: BlocBuilder<CoursesCubit, CoursesState>(
        builder: (context, state) {
          final reload = context.read<CoursesCubit>().load;

          return switch (state) {
            CoursesLoading() => const AppLoadingView(),
            CoursesError(:final message) => AppMessageView(
              message: message,
              onRetry: reload,
            ),
            CoursesLoaded(:final courses) when courses.isEmpty =>
              AppMessageView(
                message: 'لا توجد دورات متاحة حاليًا.',
                onRetry: reload,
              ),
            CoursesLoaded(:final courses) => RefreshIndicator(
              onRefresh: reload,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return CourseCard(
                    course: course,
                    onTap: () => context.push(
                      RouteNames.studentCourseDetails(course.id),
                    ),
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
