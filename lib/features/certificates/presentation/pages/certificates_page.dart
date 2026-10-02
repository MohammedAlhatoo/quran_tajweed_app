import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/presentation/state/courses_cubit.dart';
import '../../domain/entities/certificate.dart';
import '../state/certificates_cubit.dart';

/// The student's certificates. Each opens the certificate itself.
class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

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
        leading: const AppBackButton(),
        title: const Text('شهاداتي'),
      ),
      body: BlocBuilder<CertificatesCubit, CertificatesState>(
        builder: (context, state) {
          final reload = context.read<CertificatesCubit>().load;

          return switch (state) {
            CertificatesLoading() => const AppLoadingView(),
            CertificatesError(:final message) => AppMessageView(
              message: message,
              onRetry: reload,
            ),
            CertificatesLoaded(:final certificates) when certificates.isEmpty =>
              AppMessageView(
                message:
                    'لا توجد شهادات بعد. تصدر الشهادة عند النجاح في '
                    'الاختبار واعتماد نتيجته.',
                onRetry: reload,
              ),
            CertificatesLoaded(:final certificates) => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: certificates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final certificate = certificates[index];
                return _CertificateCard(
                  certificate: certificate,
                  courseName:
                      coursesById[certificate.courseId]?.name ??
                      'دورة غير متاحة',
                  onTap: () => context.push(
                    RouteNames.studentExamCertificate(certificate.examId),
                  ),
                );
              },
            ),
          };
        },
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.certificate,
    required this.courseName,
    required this.onTap,
  });

  final Certificate certificate;
  final String courseName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.iconTileBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 22,
                    color: AppColors.optionSelectedText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cairo(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          lineHeight: 20,
                        ),
                      ),
                      Text(
                        '${certificate.certificateNumber} · '
                        '${certificate.finalScore} من 100',
                        style: AppTextStyles.cairo(
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppColors.textHint,
                          lineHeight: 16.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SvgPicture.asset(AppAssets.chevronIcon, width: 16, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
