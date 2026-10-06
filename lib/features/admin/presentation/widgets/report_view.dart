import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/exam_report.dart';
import '../state/report_cubit.dart';

/// The report of the scope held by the [ReportCubit] above it: the totals,
/// the breakdown by unit and by course, and the examinations themselves.
class ReportView extends StatelessWidget {
  const ReportView({super.key, this.header});

  /// Shown above the loaded report, such as the button that exports it.
  final Widget Function(ExamReport report)? header;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        final reload = context.read<ReportCubit>().load;

        return switch (state) {
          ReportLoading() => const AppLoadingView(),
          ReportError(:final message) => AppMessageView(
            message: message,
            onRetry: reload,
          ),
          ReportLoaded(:final report) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                ?header?.call(report),
                _Totals(report),
                if (report.byUnit.isNotEmpty) ...[
                  _SectionTitle(report.unitTitle),
                  for (final group in report.byUnit) _GroupCard(group),
                ],
                if (report.byCourse.isNotEmpty) ...[
                  const _SectionTitle('حسب الدورة'),
                  for (final group in report.byCourse) _GroupCard(group),
                ],
                const _SectionTitle('الامتحانات'),
                if (report.exams.isEmpty)
                  const _Card(child: _Text('لا توجد امتحانات في هذا النطاق.'))
                else
                  for (final exam in report.exams) _ExamCard(exam),
              ],
            ),
          ),
        };
      },
    );
  }
}

String _number(double? value, {String suffix = ''}) =>
    value == null ? '—' : '${value.toStringAsFixed(1)}$suffix';

class _Totals extends StatelessWidget {
  const _Totals(this.report);

  final ExamReport report;

  @override
  Widget build(BuildContext context) {
    final totals = report.totals;
    final tiles = [
      ('الطلاب', '${report.students}'),
      ('الامتحانات', '${totals.exams}'),
      ('بانتظار المراجعة', '${totals.awaitingReview}'),
      ('قيد التنفيذ', '${totals.inProgress}'),
      ('المعتمدة', '${totals.approved}'),
      ('الناجحون', '${totals.passed}'),
      ('الراسبون', '${totals.failed}'),
      ('نسبة النجاح', _number(totals.passRate, suffix: '%')),
      ('متوسط الدرجة', _number(totals.averageScore)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        for (final (label, value) in tiles)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.cairo(
                    size: 18,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                    lineHeight: 26,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cairo(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                    lineHeight: 16.5,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        text,
        style: AppTextStyles.cairo(
          size: 14,
          weight: FontWeight.w700,
          color: AppColors.title,
          lineHeight: 20,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _Text extends StatelessWidget {
  const _Text(this.text, {this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: strong ? 14 : 12,
        weight: strong ? FontWeight.w700 : FontWeight.w500,
        color: strong ? AppColors.textPrimary : AppColors.muted,
        lineHeight: strong ? 20 : 18,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard(this.group);

  final ReportGroup group;

  @override
  Widget build(BuildContext context) {
    final totals = group.totals;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Text(group.label, strong: true),
          const SizedBox(height: 4),
          _Text(
            'الامتحانات: ${totals.exams} · بانتظار المراجعة: '
            '${totals.awaitingReview} · ناجح: ${totals.passed} · '
            'راسب: ${totals.failed} · نسبة النجاح: '
            '${_number(totals.passRate, suffix: '%')}',
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard(this.exam);

  final ReportExam exam;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final date = exam.date;
    final finalScore = exam.finalScore;
    final passed = exam.passed ?? false;

    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Text(exam.studentName, strong: true),
                _Text(
                  [
                    exam.courseName,
                    if (date != null) _formatDate(date),
                  ].join(' · '),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (finalScore != null)
            StatusChip(
              '${passed ? 'ناجح' : 'راسب'} · $finalScore',
              tone: passed ? StatusTone.success : StatusTone.danger,
            )
          else
            StatusChip(
              exam.status.label,
              tone: exam.status.isAwaitingReview
                  ? StatusTone.info
                  : StatusTone.neutral,
            ),
        ],
      ),
    );
  }
}
