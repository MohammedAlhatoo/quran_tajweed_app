import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/presentation/state/start_exam_cubit.dart';
import '../../../questions/domain/services/question_selector.dart';
import '../../../supervisor/domain/services/exam_scoring.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/tajweed_rule_group.dart';
import '../state/course_details_cubit.dart';

class CourseDetailsPage extends StatelessWidget {
  const CourseDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        shape: const Border(),
        leading: const AppBackButton(),
        title: const Text('تفاصيل الدورة'),
      ),
      body: BlocBuilder<CourseDetailsCubit, CourseDetailsState>(
        builder: (context, state) {
          return switch (state) {
            CourseDetailsLoading() => const AppLoadingView(),
            CourseDetailsError(:final message) => AppMessageView(
              message: message,
              onRetry: context.read<CourseDetailsCubit>().load,
            ),
            CourseDetailsLoaded() => _CourseDetails(state),
          };
        },
      ),
    );
  }
}

class _CourseDetails extends StatelessWidget {
  const _CourseDetails(this.state);

  final CourseDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    final course = state.course;
    final ruleGroups = state.ruleGroups;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _HeaderCard(course: course),
              if (course.objectives.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('أهداف الدورة'),
                const SizedBox(height: 12),
                for (final (index, objective) in course.objectives.indexed) ...[
                  if (index > 0) const SizedBox(height: 10),
                  _Objective(objective),
                ],
              ],
              const SizedBox(height: 24),
              const _SectionTitle('معلومات الامتحان'),
              const SizedBox(height: 12),
              const _ExamInfoCard(),
              if (ruleGroups.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('الأحكام الرئيسية'),
                const SizedBox(height: 12),
                for (final (index, group) in ruleGroups.indexed) ...[
                  if (index > 0) const SizedBox(height: 8),
                  _RuleGroupSection(group),
                ],
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.isAwaitingReview) ...[
                  const _AwaitingReviewNotice(),
                  const SizedBox(height: 12),
                ],
                _ExamButton(
                  courseId: course.id,
                  openExam: state.openExam,
                  isAwaitingReview: state.isAwaitingReview,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Starts an examination of the course, or continues the open one.
class _ExamButton extends StatelessWidget {
  const _ExamButton({
    required this.courseId,
    required this.openExam,
    required this.isAwaitingReview,
  });

  final String courseId;
  final Exam? openExam;
  final bool isAwaitingReview;

  void _start(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<StartExamCubit>().start(
      student: authState.user,
      courseId: courseId,
    );
  }

  /// Opens the examination, and reads its status again once the student comes
  /// back from it.
  Future<void> _open(BuildContext context, String examId) async {
    final details = context.read<CourseDetailsCubit>();
    await context.push(RouteNames.studentExam(examId));
    if (!details.isClosed) await details.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StartExamCubit, StartExamState>(
      listener: (context, state) {
        switch (state) {
          case StartExamReady(:final exam):
            _open(context, exam.id);
          case StartExamError(:final message):
            showAppSnackBar(context, message, isError: true);
          case StartExamIdle() || StartExamLoading():
            break;
        }
      },
      builder: (context, state) {
        if (isAwaitingReview) {
          return const _ExamActionButton(
            label: 'الامتحان قيد المراجعة',
            onPressed: null,
          );
        }
        if (openExam case final exam?) {
          return _ExamActionButton(
            label: 'متابعة الامتحان',
            onPressed: () => _open(context, exam.id),
          );
        }
        return _ExamActionButton(
          label: 'تقديم الامتحان',
          isLoading: state is StartExamLoading,
          onPressed: () => _start(context),
        );
      },
    );
  }
}

/// The button of this page as Figma draws it: its own green, 48 high, over a
/// light neutral shadow.
class _ExamActionButton extends StatelessWidget {
  const _ExamActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  static const Color _color = Color(0xFF18675F);

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        // The disabled fill is translucent, so a shadow would show through it.
        boxShadow: onPressed == null
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 4),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: Color(0x0F000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _color,
          minimumSize: const Size.fromHeight(48),
        ),
        // Stays enabled-looking while loading, but ignores taps.
        onPressed: isLoading ? () {} : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _AwaitingReviewNotice extends StatelessWidget {
  const _AwaitingReviewNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'امتحانك في هذه الدورة قيد المراجعة. '
      'لا يمكن تقديم امتحان جديد قبل اعتماد نتيجته.',
      textAlign: TextAlign.center,
      style: AppTextStyles.cairo(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.muted,
        lineHeight: 18,
      ),
    );
  }
}

/// What the examination consists of. It has no time limit, so none is shown.
class _ExamInfoCard extends StatelessWidget {
  const _ExamInfoCard();

  static const int _fullMark =
      ExamScoring.maxRecitationScore + ExamScoring.maxTheoryScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: const Column(
        children: [
          _InfoRow(
            'عدد الأسئلة النظرية',
            '${QuestionSelector.examQuestionCount}',
          ),
          _InfoRow('درجة التلاوة', '${ExamScoring.maxRecitationScore}'),
          _InfoRow('درجة الأسئلة', '${ExamScoring.maxTheoryScore}'),
          _InfoRow('درجة النجاح', '${ExamScoring.passMark}/$_fullMark'),
          _InfoRow('تسجيل التلاوة', 'ضمن الامتحان'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cairo(
                size: 12,
                weight: FontWeight.w500,
                color: AppColors.bodyText,
                lineHeight: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.cairo(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.title,
              lineHeight: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// One chapter of the course's rules. It opens to show the rules, so a course
/// with many of them stays short.
class _RuleGroupSection extends StatefulWidget {
  const _RuleGroupSection(this.group);

  final TajweedRuleGroup group;

  @override
  State<_RuleGroupSection> createState() => _RuleGroupSectionState();
}

class _RuleGroupSectionState extends State<_RuleGroupSection> {
  static const Color _openBackground = Color(0xFFD2EBE7);
  static const Color _openBorder = Color(0xFFB2DED8);
  static const Color _openText = Color(0xFF11554F);

  bool _isOpen = false;

  ShapeBorder _shape(Color border) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: border),
  );

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    // Only the title row is outlined and highlighted, through the theme of
    // its tile; the rules below it sit on the page.
    return ListTileTheme.merge(
      tileColor: _isOpen ? _openBackground : Colors.transparent,
      shape: _shape(_isOpen ? _openBorder : AppColors.line),
      child: ExpansionTile(
        onExpansionChanged: (isOpen) => setState(() => _isOpen = isOpen),
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: _openText,
        collapsedIconColor: AppColors.muted,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(top: 8),
        expandedAlignment: AlignmentDirectional.topStart,
        title: Text(
          group.label,
          style: AppTextStyles.cairo(
            size: 13,
            weight: FontWeight.w700,
            color: _isOpen ? _openText : AppColors.title,
            lineHeight: 20,
          ),
        ),
        subtitle: Text(
          'عدد الأحكام: ${group.rules.length}',
          style: AppTextStyles.cairo(
            size: 11,
            weight: FontWeight.w500,
            color: _isOpen ? _openText : AppColors.muted,
            lineHeight: 16.5,
          ),
        ),
        children: [
          _RuleTagGrid([for (final rule in group.rules) rule.name]),
        ],
      ),
    );
  }
}

/// The rules of a chapter on a grid of four columns, or fewer on a narrow
/// screen. A name too long for one column takes as many as it needs, and
/// wraps onto a second line only when the whole row is too narrow for it.
class _RuleTagGrid extends StatelessWidget {
  const _RuleTagGrid(this.names);

  static const int _maxColumns = 4;
  static const double _gap = 8;
  static const double _minColumnWidth = 60;

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ((width + _gap) / (_minColumnWidth + _gap))
            .floor()
            .clamp(1, _maxColumns);
        // Rounded down, so a full row never spills onto the next one.
        final columnWidth = ((width - _gap * (columns - 1)) / columns)
            .floorToDouble();
        double widthOf(int span) => columnWidth * span + _gap * (span - 1);

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final name in names)
              SizedBox(
                width: widthOf(
                  _spanOf(
                    name,
                    columns: columns,
                    widthOf: widthOf,
                    textScaler: textScaler,
                    textDirection: textDirection,
                  ),
                ),
                child: _RuleTag(name),
              ),
          ],
        );
      },
    );
  }

  /// The number of columns [name] needs to stay on one line.
  int _spanOf(
    String name, {
    required int columns,
    required double Function(int span) widthOf,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: name, style: _RuleTag.textStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final needed = painter.width + _RuleTag.horizontalInset;
    painter.dispose();

    for (var span = 1; span < columns; span++) {
      if (needed <= widthOf(span)) return span;
    }
    return columns;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: AppTextStyles.cairo(
                    size: 16,
                    weight: FontWeight.w700,
                    color: AppColors.title,
                    lineHeight: 24,
                  ),
                ),
                if (course.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.description,
                    style: AppTextStyles.cairo(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.muted,
                      lineHeight: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4F2),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    course.level.label,
                    style: AppTextStyles.cairo(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF1A6B64),
                      lineHeight: 16.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF7F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5EBE8)),
            ),
            child: SvgPicture.asset(
              AppAssets.courseBookIcon,
              width: 32,
              height: 32,
            ),
          ),
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
    return Text(
      text,
      style: AppTextStyles.cairo(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.title,
        lineHeight: 20,
      ),
    );
  }
}

class _Objective extends StatelessWidget {
  const _Objective(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1B6B64),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(AppAssets.checkIcon, width: 10, height: 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.cairo(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.bodyText,
              lineHeight: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleTag extends StatelessWidget {
  const _RuleTag(this.name);

  static const double _horizontalPadding = 6;

  /// The padding and the border on both sides of the name.
  static const double horizontalInset = (_horizontalPadding + 1) * 2 + 1;

  static final TextStyle textStyle = AppTextStyles.cairo(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.tagText,
    lineHeight: 16,
  );

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 33),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: 7.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(name, textAlign: TextAlign.center, style: textStyle),
    );
  }
}
