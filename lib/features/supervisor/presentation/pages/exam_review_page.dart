import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../exams/domain/entities/exam_segment.dart';
import '../../../questions/presentation/widgets/exam_action_button.dart';
import '../../domain/services/exam_scoring.dart';
import '../state/evaluation_cubit.dart';
import '../state/exam_review_cubit.dart';
import '../state/recitation_playback_cubit.dart';

/// One submitted examination as the supervisor reviews it: the student, the
/// Quran segment, the recitation recording, the theory answers, and the
/// evaluation that approves the result.
class ExamReviewPage extends StatelessWidget {
  const ExamReviewPage({super.key, required this.onApproved});

  /// Leaves the examination after its result is approved.
  final VoidCallback onApproved;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        shape: const Border(),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'الرجوع',
          onPressed: () => Navigator.of(context).maybePop(),
          // The asset points left; the design shows it turned around.
          icon: RotatedBox(
            quarterTurns: 2,
            child: SvgPicture.asset(AppAssets.questionsBackIcon),
          ),
        ),
        title: const Text('مراجعة الاختبار'),
      ),
      body: BlocBuilder<ExamReviewCubit, ExamReviewState>(
        builder: (context, state) => switch (state) {
          ExamReviewLoading() => const AppLoadingView(),
          ExamReviewError(:final message) => AppMessageView(
            message: message,
            onRetry: context.read<ExamReviewCubit>().load,
          ),
          ExamReviewLoaded() => _ReviewView(state, onApproved: onApproved),
        },
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView(this.review, {required this.onApproved});

  final ExamReviewLoaded review;
  final VoidCallback onApproved;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static String _segmentReference(ExamSegment segment) {
    final ayahs = segment.ayahFrom == segment.ayahTo
        ? 'الآية ${segment.ayahFrom}'
        : 'الآيات ${segment.ayahFrom} - ${segment.ayahTo}';
    return 'سورة ${SurahNames.of(segment.surah)} · $ayahs · '
        'الصفحة ${segment.page}';
  }

  @override
  Widget build(BuildContext context) {
    final student = review.student;
    final phone = student.phone;
    final submittedAt =
        review.submission.submittedAt ?? review.exam.submittedAt;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          const _SectionTitle('الطالب'),
          _InfoCard(
            rows: [
              ('الاسم', student.name),
              if (phone != null && phone.isNotEmpty) ('الهاتف', phone),
              ('البريد الإلكتروني', student.email),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('الاختبار'),
          _InfoCard(
            rows: [
              ('الدورة', review.course?.name ?? 'دورة غير متاحة'),
              ('المقطع', _segmentReference(review.segment)),
              ('الحالة', review.exam.status.label),
              if (submittedAt != null)
                ('تاريخ الإرسال', _formatDate(submittedAt)),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('تسجيل التلاوة'),
          _RecordingCard(recordingPath: review.submission.recordingPath),
          const SizedBox(height: 24),
          const _SectionTitle('إجابات الأسئلة النظرية'),
          if (review.questions.isEmpty)
            const _Card(child: _Value('أسئلة هذا الاختبار غير متاحة.'))
          else
            for (final question in review.questions) ...[
              _AnswerCard(
                order: question.order,
                question: question.question,
                answer: review.answerTo(question),
                correctAnswer: review.correctAnswerTo(question),
              ),
              const SizedBox(height: 14),
            ],
          const SizedBox(height: 10),
          const _SectionTitle('التقييم'),
          if (review.exam.status.isAwaitingReview)
            _EvaluationForm(
              theoryScore: review.theoryScore,
              onApproved: onApproved,
            )
          else
            const _Card(child: _Value('تم اعتماد نتيجة هذا الاختبار.')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTextStyles.cairo(
          size: 14,
          weight: FontWeight.w700,
          color: AppColors.muted,
          lineHeight: 20,
        ),
      ),
    );
  }
}

/// The bordered card of the questions and submission review screens.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.optionBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: 12,
        weight: FontWeight.w600,
        color: AppColors.muted,
        lineHeight: 16,
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: 15,
        weight: FontWeight.w600,
        color: AppColors.title,
        lineHeight: 24.38,
      ),
    );
  }
}

/// A card of labelled values, one under the other.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String label, String value)> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, (label, value)) in rows.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _Label(label),
            const SizedBox(height: 2),
            _Value(value),
          ],
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.order,
    required this.question,
    required this.answer,
    required this.correctAnswer,
  });

  final int order;
  final String question;

  /// Null when the student left the question without an answer.
  final String? answer;

  /// Null when the correct answer is not stored.
  final String? correctAnswer;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('السؤال $order'),
          const SizedBox(height: 4),
          _Value(question),
          const SizedBox(height: 6),
          Text(
            answer ?? 'لم تتم الإجابة',
            style: AppTextStyles.cairo(
              size: 15,
              weight: FontWeight.w700,
              color: answer != null && answer == correctAnswer
                  ? AppColors.optionSelectedText
                  : AppColors.danger,
              lineHeight: 22.5,
            ),
          ),
          if (correctAnswer != null && answer != correctAnswer) ...[
            const SizedBox(height: 4),
            _Label('الإجابة الصحيحة: $correctAnswer'),
          ],
        ],
      ),
    );
  }
}

/// Plays the student's recitation.
class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.recordingPath});

  final String recordingPath;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecitationPlaybackCubit, PlaybackState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final cubit = context.read<RecitationPlaybackCubit>();
        final (
          String label,
          VoidCallback? onPressed,
          Widget icon,
        ) = switch (state.status) {
          PlaybackStatus.idle => (
            'الاستماع إلى التلاوة',
            () => cubit.play(recordingPath),
            const Icon(
              Icons.play_arrow_rounded,
              size: 26,
              color: AppColors.onPrimary,
            ),
          ),
          PlaybackStatus.loading => (
            'جارٍ تحميل التسجيل...',
            null,
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          PlaybackStatus.playing => (
            'إيقاف التشغيل',
            cubit.stop,
            const Icon(
              Icons.stop_rounded,
              size: 26,
              color: AppColors.onPrimary,
            ),
          ),
        };

        return _Card(
          child: Row(
            children: [
              Semantics(
                button: true,
                label: label,
                child: Tooltip(
                  message: label,
                  child: GestureDetector(
                    onTap: onPressed,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: AppColors.recordButtonGradient,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: icon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: ExcludeSemantics(child: _Value(label))),
            ],
          ),
        );
      },
    );
  }
}

/// The recitation score entered by the supervisor, the scores derived from
/// it, and the approval of the result.
class _EvaluationForm extends StatelessWidget {
  const _EvaluationForm({required this.theoryScore, required this.onApproved});

  /// Null when the theory score cannot be calculated.
  final int? theoryScore;
  final VoidCallback onApproved;

  Future<void> _approve(BuildContext context, int theoryScore) async {
    final cubit = context.read<EvaluationCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اعتماد النتيجة'),
        content: const Text(
          'لن تتمكن من تعديل الدرجة بعد الاعتماد. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.approve(theoryScore: theoryScore);
  }

  @override
  Widget build(BuildContext context) {
    final theoryScore = this.theoryScore;
    if (theoryScore == null) {
      return const _Card(
        child: _Value(
          'تعذّر احتساب درجة الأسئلة النظرية لأن الإجابات الصحيحة غير متاحة. '
          'لا يمكن اعتماد النتيجة.',
        ),
      );
    }

    return BlocConsumer<EvaluationCubit, EvaluationState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null ||
          (current.status == EvaluationStatus.approved &&
              previous.status != EvaluationStatus.approved),
      listener: (context, state) {
        if (state.status == EvaluationStatus.approved) {
          onApproved();
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final editing = state.status == EvaluationStatus.editing;
        final recitationScore = state.recitationScore;
        final finalScore = recitationScore == null
            ? null
            : ExamScoring.finalScore(
                recitationScore: recitationScore,
                theoryScore: theoryScore,
              );
        final passed =
            finalScore != null &&
            ExamScoring.resultOf(finalScore) == ExamScoring.passed;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label(
                    'درجة التلاوة (من ${ExamScoring.maxRecitationScore})',
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    enabled: editing,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      hintText: '0 - ${ExamScoring.maxRecitationScore}',
                    ),
                    onChanged: context
                        .read<EvaluationCubit>()
                        .setRecitationScore,
                  ),
                  const SizedBox(height: 12),
                  const _Label('درجة الأسئلة النظرية'),
                  const SizedBox(height: 2),
                  _Value('$theoryScore / ${ExamScoring.maxTheoryScore}'),
                  const SizedBox(height: 12),
                  const _Label('الدرجة النهائية'),
                  const SizedBox(height: 2),
                  _Value(finalScore == null ? '—' : '$finalScore / 100'),
                  const SizedBox(height: 12),
                  const _Label('النتيجة'),
                  const SizedBox(height: 2),
                  Text(
                    finalScore == null
                        ? '—'
                        : passed
                        ? 'ناجح'
                        : 'راسب',
                    style: AppTextStyles.cairo(
                      size: 15,
                      weight: FontWeight.w700,
                      color: finalScore == null
                          ? AppColors.title
                          : passed
                          ? AppColors.optionSelectedText
                          : AppColors.danger,
                      lineHeight: 22.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ExamActionButton(
              label: 'اعتماد النتيجة',
              isLoading: state.status == EvaluationStatus.saving,
              onPressed: editing && recitationScore != null
                  ? () => _approve(context, theoryScore)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
