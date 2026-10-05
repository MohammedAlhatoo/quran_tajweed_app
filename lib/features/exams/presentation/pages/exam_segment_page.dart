import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/exam_segment.dart';
import '../../domain/entities/exam_status.dart';
import '../../../../router/route_names.dart';
import '../../../questions/presentation/state/questions_cubit.dart';
import '../../../questions/presentation/widgets/exam_action_button.dart';
import '../../../quran/presentation/widgets/segment_text.dart';
import '../state/exam_cubit.dart';
import '../state/recording_cubit.dart';
import '../widgets/mushaf_frame.dart';
import '../widgets/recording_controls.dart';

/// The examination screen: the assigned Quran segment inside a Mushaf page
/// frame, above the recitation recording bar. The theory questions open from
/// here once the recitation is uploaded.
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
            ExamLoaded(:final exam, :final segment, :final ayahs) => Column(
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
                        // Centered when it is shorter than the page, scrolled
                        // when it is longer.
                        child: Center(
                          child: SingleChildScrollView(
                            child: SegmentText(ayahs: ayahs),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The recording and the answers can change only until the
                // examination is submitted.
                if (exam.status == ExamStatus.inProgress) ...[
                  _QuestionsEntry(examId: exam.id),
                  const RecordingControls(),
                ],
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

/// Opens the theory questions once the recitation is uploaded.
class _QuestionsEntry extends StatelessWidget {
  const _QuestionsEntry({required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecordingCubit, RecordingState, bool>(
      selector: (state) => state.status == RecordingStatus.uploaded,
      builder: (context, uploaded) {
        if (!uploaded) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: ExamActionButton(
            label: 'الانتقال إلى الأسئلة',
            onPressed: () => context.push(
              RouteNames.studentExamQuestions(examId),
              extra: context.read<QuestionsCubit>(),
            ),
          ),
        );
      },
    );
  }
}
