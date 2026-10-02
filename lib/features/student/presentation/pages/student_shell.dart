import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../exams/presentation/state/exam_history_cubit.dart';
import '../widgets/student_bottom_nav.dart';

/// The frame of the student's area: the current tab above the bottom bar.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// The position of the exams tab among the shell branches.
  static const int _examsTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: StudentBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // An examination may have been started since the last visit.
          if (index == _examsTabIndex) context.read<ExamHistoryCubit>().load();
          navigationShell.goBranch(
            index,
            // Tapping the current tab returns to its first screen.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
