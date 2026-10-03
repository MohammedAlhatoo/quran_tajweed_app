import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../questions/presentation/widgets/exam_action_button.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/entities/recitation_error.dart';
import '../state/exam_result_cubit.dart';

/// The result of one of the student's examinations: the two scores, the
/// final score, whether it was passed, and the supervisor's notes and
/// detailed Tajweed errors, once the supervisor approves it.
class ExamResultPage extends StatelessWidget {
  const ExamResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('نتيجة الاختبار'),
      ),
      body: BlocBuilder<ExamResultCubit, ExamResultState>(
        builder: (context, state) => switch (state) {
          ExamResultLoading() => const AppLoadingView(),
          ExamResultError(:final message) => AppMessageView(
            message: message,
            onRetry: context.read<ExamResultCubit>().load,
          ),
          ExamResultLoaded(evaluation: null, :final exam) => AppMessageView(
            message: exam.status.isAwaitingReview
                ? 'اختبارك بانتظار مراجعة المشرف. ستظهر النتيجة بعد اعتمادها.'
                : 'لا توجد نتيجة معتمدة لهذا الاختبار بعد.',
            onRetry: context.read<ExamResultCubit>().load,
          ),
          ExamResultLoaded(:final evaluation?) => _ResultView(
            state: state,
            evaluation: evaluation,
          ),
        },
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.evaluation});

  final ExamResultLoaded state;
  final Evaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final passed = evaluation.passed;
    final color = passed ? AppColors.optionSelectedText : AppColors.danger;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: passed
                        ? AppColors.optionSelectedMark
                        : AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed ? Icons.check_rounded : Icons.close_rounded,
                    size: 36,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                passed ? 'ناجح' : 'راسب',
                textAlign: TextAlign.center,
                style: AppTextStyles.cairo(
                  size: 20,
                  weight: FontWeight.w700,
                  color: color,
                  lineHeight: 30,
                ),
              ),
              Text(
                state.course?.name ?? 'دورة غير متاحة',
                textAlign: TextAlign.center,
                style: AppTextStyles.cairo(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  lineHeight: 22,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.optionBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ScoreRow('درجة التلاوة', evaluation.recitationScore, 80),
                    const Divider(height: 24, color: AppColors.lineSoft),
                    _ScoreRow(
                      'درجة الأسئلة النظرية',
                      evaluation.theoryScore,
                      20,
                    ),
                    const Divider(height: 24, color: AppColors.lineSoft),
                    _ScoreRow(
                      'الدرجة النهائية',
                      evaluation.finalScore,
                      100,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              if (!passed) ...[
                const SizedBox(height: 16),
                Text(
                  'درجة النجاح 70 من 100. يمكنك إعادة الاختبار من صفحة الدورة.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cairo(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                    lineHeight: 21,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const _SectionTitle('التقرير التفصيلي'),
              if (evaluation.feedback case final feedback?) ...[
                _ReportCard(
                  children: [
                    const _ReportLabel('الملاحظات العامة'),
                    const SizedBox(height: 4),
                    _ReportText(feedback),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              const _ReportLabel('تقرير الأخطاء'),
              const SizedBox(height: 8),
              if (evaluation.detailedErrors.isEmpty)
                const _ReportCard(
                  children: [
                    _ReportText('لم يتم تسجيل أخطاء تفصيلية لهذا التقييم.'),
                  ],
                )
              else
                for (final (index, error)
                    in evaluation.detailedErrors.indexed) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _ErrorCard(number: index + 1, error: error),
                ],
            ],
          ),
        ),
        // Only a passed examination has a certificate.
        if (state.certificate != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 13, 24, 16),
              child: ExamActionButton(
                label: 'عرض الشهادة',
                onPressed: () => context.push(
                  RouteNames.studentExamCertificate(state.exam.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.cairo(
          size: 16,
          weight: FontWeight.w700,
          color: AppColors.title,
          lineHeight: 24,
        ),
      ),
    );
  }
}

/// The bordered card of the scores, used for each part of the report.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.optionBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ReportLabel extends StatelessWidget {
  const _ReportLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: 13,
        weight: FontWeight.w600,
        color: AppColors.muted,
        lineHeight: 20,
      ),
    );
  }
}

class _ReportText extends StatelessWidget {
  const _ReportText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: 14,
        weight: FontWeight.w500,
        color: AppColors.bodyText,
        lineHeight: 22,
      ),
    );
  }
}

/// One Tajweed error of the report: its rule, its position and its
/// description.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.number, required this.error});

  final int number;
  final RecitationError error;

  @override
  Widget build(BuildContext context) {
    final position = error.position;

    return _ReportCard(
      children: [
        _ReportLabel('الخطأ $number'),
        const SizedBox(height: 4),
        Text(
          error.ruleName ?? 'قاعدة غير متاحة',
          style: AppTextStyles.cairo(
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.title,
            lineHeight: 24,
          ),
        ),
        if (position != null) _ReportLabel(position),
        if (error.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ReportText(error.description),
        ],
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.score, this.max, {this.emphasized = false});

  final String label;
  final int score;
  final int max;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final weight = emphasized ? FontWeight.w700 : FontWeight.w600;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.cairo(
              size: 14,
              weight: weight,
              color: AppColors.bodyText,
              lineHeight: 22,
            ),
          ),
        ),
        Text(
          '$score / $max',
          textDirection: TextDirection.ltr,
          style: AppTextStyles.cairo(
            size: emphasized ? 17 : 15,
            weight: FontWeight.w700,
            color: AppColors.title,
            lineHeight: 24,
          ),
        ),
      ],
    );
  }
}
