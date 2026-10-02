import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../exams/presentation/state/exam_result_cubit.dart';
import '../../domain/entities/certificate.dart';

/// The certificate of one passed examination, shown to its student.
class CertificatePage extends StatelessWidget {
  const CertificatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final studentName = authState is AuthAuthenticated
        ? authState.user.name
        : '';

    return Scaffold(
      backgroundColor: AppColors.mushafBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('الشهادة'),
      ),
      body: BlocBuilder<ExamResultCubit, ExamResultState>(
        builder: (context, state) => switch (state) {
          ExamResultLoading() => const AppLoadingView(),
          ExamResultError(:final message) => AppMessageView(
            message: message,
            onRetry: context.read<ExamResultCubit>().load,
          ),
          ExamResultLoaded(:final certificate?, :final course) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _CertificateSheet(
                certificate: certificate,
                studentName: studentName,
                courseName: course?.name ?? 'التجويد',
              ),
            ),
          ),
          ExamResultLoaded() => const AppMessageView(
            message: 'لا توجد شهادة لهذا الاختبار.',
          ),
        },
      ),
    );
  }
}

class _CertificateSheet extends StatelessWidget {
  const _CertificateSheet({
    required this.certificate,
    required this.studentName,
    required this.courseName,
  });

  final Certificate certificate;
  final String studentName;
  final String courseName;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final issuedAt = certificate.issuedAt;
    TextStyle text(double size, FontWeight weight, Color color) =>
        AppTextStyles.cairo(
          size: size,
          weight: weight,
          color: color,
          lineHeight: size * 1.7,
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mushafPage,
        border: Border.all(color: AppColors.mushafBorder, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.mushafInnerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppColors.mushafCorner,
            ),
            const SizedBox(height: 8),
            Text(
              'شهادة اجتياز',
              style: text(22, FontWeight.w700, AppColors.examHeader),
            ),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: text(12, FontWeight.w600, AppColors.mushafPageNumber),
            ),
            const SizedBox(height: 20),
            Text(
              'تشهد المنصة بأن الطالب',
              style: text(13, FontWeight.w500, AppColors.bodyText),
            ),
            Text(
              studentName,
              textAlign: TextAlign.center,
              style: text(20, FontWeight.w700, AppColors.ink),
            ),
            Text(
              'قد اجتاز اختبار دورة',
              style: text(13, FontWeight.w500, AppColors.bodyText),
            ),
            Text(
              courseName,
              textAlign: TextAlign.center,
              style: text(18, FontWeight.w700, AppColors.examHeader),
            ),
            const SizedBox(height: 12),
            Text(
              'بدرجة ${certificate.finalScore} من 100',
              style: text(15, FontWeight.w700, AppColors.optionSelectedText),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.mushafOutline),
            const SizedBox(height: 12),
            Text(
              'رقم الشهادة',
              style: text(11, FontWeight.w500, AppColors.muted),
            ),
            Text(
              certificate.certificateNumber,
              textDirection: TextDirection.ltr,
              style: text(14, FontWeight.w700, AppColors.title),
            ),
            if (issuedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'تاريخ الإصدار',
                style: text(11, FontWeight.w500, AppColors.muted),
              ),
              Text(
                _formatDate(issuedAt),
                textDirection: TextDirection.ltr,
                style: text(14, FontWeight.w700, AppColors.title),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
