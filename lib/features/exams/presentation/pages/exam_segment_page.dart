import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/exam_segment.dart';
import '../../domain/entities/exam_status.dart';
import '../state/exam_cubit.dart';
import '../widgets/mushaf_frame.dart';
import '../widgets/recording_controls.dart';

/// The examination screen: the assigned Quran segment inside a Mushaf page
/// frame, above the recitation recording bar. The theory questions are added
/// in their own step.
class ExamSegmentPage extends StatelessWidget {
  const ExamSegmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamCubit, ExamState>(
      builder: (context, state) {
        final segment = state is ExamLoaded ? state.segment : null;

        return Scaffold(
          backgroundColor: AppColors.mushafBackground,
          appBar: AppBar(
            backgroundColor: AppColors.examHeader,
            shape: const Border(),
            leading: IconButton(
              tooltip: 'الرجوع',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: SvgPicture.asset(
                AppAssets.backLightIcon,
                width: 20,
                height: 20,
              ),
            ),
            title: segment == null ? null : _SegmentTitle(segment),
          ),
          body: switch (state) {
            ExamLoading() => const AppLoadingView(),
            ExamError(:final message) => AppMessageView(
              message: message,
              onRetry: context.read<ExamCubit>().load,
            ),
            ExamLoaded(:final exam, :final segment) => Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: exam.status != ExamStatus.inProgress,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: MushafFrame(
                        page: segment.page,
                        child: const _SegmentTextUnavailable(),
                      ),
                    ),
                  ),
                ),
                // The recording can change only until the examination is
                // submitted.
                if (exam.status == ExamStatus.inProgress)
                  const RecordingControls(),
              ],
            ),
          },
        );
      },
    );
  }
}

class _SegmentTitle extends StatelessWidget {
  const _SegmentTitle(this.segment);

  final ExamSegment segment;

  @override
  Widget build(BuildContext context) {
    final ayahs = segment.ayahFrom == segment.ayahTo
        ? 'الآية ${segment.ayahFrom}'
        : 'الآيات ${segment.ayahFrom} - ${segment.ayahTo}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'سورة ${SurahNames.of(segment.surah)}',
          style: AppTextStyles.cairo(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.onPrimary,
            lineHeight: 20,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '$ayahs - الصفحة ${segment.page}',
          style: AppTextStyles.cairo(
            size: 11,
            weight: FontWeight.w500,
            color: AppColors.examHeaderSubtitle,
            lineHeight: 16.5,
          ),
        ),
      ],
    );
  }
}

/// Stands in for the segment text until the approved Quran text and font are
/// added to the app. No Quran text is rendered from any other source.
class _SegmentTextUnavailable extends StatelessWidget {
  const _SegmentTextUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'نص المقطع غير متاح بعد.\nاقرأ المقطع المحدد أعلاه من المصحف.',
          textAlign: TextAlign.center,
          style: AppTextStyles.cairo(
            size: 13,
            weight: FontWeight.w500,
            color: AppColors.mushafPageNumber,
            lineHeight: 22,
          ),
        ),
      ),
    );
  }
}
