import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';

/// The exams tab. Empty for now; the history is filled in when the
/// examination system is implemented.
class ExamHistoryPage extends StatelessWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الاختبارات'),
      ),
      body: const AppMessageView(message: 'لا توجد اختبارات بعد.'),
    );
  }
}
