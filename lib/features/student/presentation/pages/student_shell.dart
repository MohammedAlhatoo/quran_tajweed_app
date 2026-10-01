import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/student_bottom_nav.dart';

/// The frame of the student's area: the current tab above the bottom bar.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: StudentBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab returns to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
