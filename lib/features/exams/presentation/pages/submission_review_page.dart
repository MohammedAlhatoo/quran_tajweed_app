import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../questions/domain/entities/exam_question.dart';
import '../../../questions/presentation/state/questions_cubit.dart';
import '../../../questions/presentation/widgets/exam_action_button.dart';
import '../state/submission_cubit.dart';

/// The last screen of an examination: the student reviews the recording
/// status and the ten answers, then submits. After submitting it confirms
/// that the examination is waiting for review.
class SubmissionReviewPage extends StatelessWidget {
  const SubmissionReviewPage({super.key, required this.onDone});

  /// Leaves the examination after it is submitted.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final questionsState = context.watch<QuestionsCubit>().state;

    return BlocConsumer<SubmissionCubit, SubmissionState>(
      listenWhen: (previous, current) => current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final submitted = state.status == SubmissionStatus.submitted;
        final submitting = state.status == SubmissionStatus.submitting;

        return PopScope(
          // A submitted examination cannot be reopened, and leaving while it
          // is being sent would hide the outcome.
          canPop: !submitted && !submitting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && submitted) onDone();
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              shape: const Border(),
              automaticallyImplyLeading: false,
              leading: submitted
                  ? null
                  : IconButton(
                      tooltip: 'الرجوع',
                      onPressed: () => Navigator.of(context).maybePop(),
                      // The asset points left; the design shows it turned
                      // around.
                      icon: RotatedBox(
                        quarterTurns: 2,
                        child: SvgPicture.asset(AppAssets.questionsBackIcon),
                      ),
                    ),
              title: Text(submitted ? 'تم الإرسال' : 'مراجعة الإرسال'),
            ),
            body: switch (questionsState) {
              _ when submitted => _SubmittedView(onDone: onDone),
              QuestionsLoading() => const AppLoadingView(),
              QuestionsError(:final message) => AppMessageView(
                message: message,
                onRetry: context.read<QuestionsCubit>().load,
              ),
              QuestionsLoaded() => _ReviewView(
                questions: questionsState,
                submission: state,
              ),
            },
          ),
        );
      },
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.questions, required this.submission});

  final QuestionsLoaded questions;
  final SubmissionState submission;

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<SubmissionCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرسال الاختبار'),
        content: const Text(
          'لن تتمكن من تعديل التسجيل أو الإجابات بعد الإرسال. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await cubit.submit(
        questions: questions.questions,
        chosen: questions.answers,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAnswered = questions.questions.every(
      (question) => questions.answers.containsKey(question.id),
    );
    final checking = submission.status == SubmissionStatus.checking;
    final canSubmit =
        submission.status == SubmissionStatus.ready &&
        submission.hasRecording &&
        allAnswered;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              _ReviewCard(
                title: 'تسجيل التلاوة',
                value: checking
                    ? 'جارٍ التحقق...'
                    : submission.hasRecording
                    ? 'تم رفع التسجيل'
                    : 'لم يُرفع التسجيل بعد',
                missing: !checking && !submission.hasRecording,
              ),
              const SizedBox(height: 28),
              for (final question in questions.questions) ...[
                _QuestionCard(
                  question: question,
                  answer: questions.answers[question.id],
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 13, 24, 16),
            child: ExamActionButton(
              label: 'إرسال الاختبار',
              isLoading: submission.status == SubmissionStatus.submitting,
              onPressed: canSubmit ? () => _submit(context) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.answer});

  final ExamQuestion question;
  final String? answer;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      label: 'السؤال ${question.order}',
      title: question.question,
      value: answer ?? 'لم تتم الإجابة',
      missing: answer == null,
    );
  }
}

/// A bordered card with a title and the student's value under it.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    this.label,
    required this.title,
    required this.value,
    required this.missing,
  });

  final String? label;
  final String title;
  final String value;

  /// The value is absent and blocks the submission.
  final bool missing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.optionBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label case final label?) ...[
            Text(
              label,
              style: AppTextStyles.cairo(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.muted,
                lineHeight: 16,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: AppTextStyles.cairo(
              size: 15,
              weight: FontWeight.w600,
              color: AppColors.title,
              lineHeight: 24.38,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.cairo(
              size: 15,
              weight: FontWeight.w700,
              color: missing ? AppColors.danger : AppColors.optionSelectedText,
              lineHeight: 22.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.optionSelectedMark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 36,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تم إرسال اختبارك',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cairo(
                      size: 18,
                      weight: FontWeight.w700,
                      color: AppColors.optionSelectedText,
                      lineHeight: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختبارك الآن بانتظار مراجعة المشرف. '
                    'ستظهر النتيجة بعد اعتمادها.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cairo(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.muted,
                      lineHeight: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 13, 24, 16),
            child: ExamActionButton(
              label: 'العودة إلى سجل الاختبارات',
              onPressed: onDone,
            ),
          ),
        ),
      ],
    );
  }
}
