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
import '../state/questions_cubit.dart';
import '../widgets/exam_action_button.dart';

/// The theory questions of an examination, one question per screen.
class QuestionsPage extends StatelessWidget {
  const QuestionsPage({super.key});

  /// Goes to the previous question, or leaves the screen from the first one.
  void _back(BuildContext context, QuestionsState state) {
    if (state is QuestionsLoaded && !state.isFirst) {
      context.read<QuestionsCubit>().previous();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuestionsCubit, QuestionsState>(
      builder: (context, state) {
        final cubit = context.read<QuestionsCubit>();
        final loaded = state is QuestionsLoaded ? state : null;

        return PopScope(
          canPop: loaded == null || loaded.isFirst,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.previous();
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              leading: AppBackButton(onPressed: () => _back(context, state)),
              title: const Text('أسئلة الأحكام'),
              actions: [
                if (loaded != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 24),
                    child: Center(
                      child: Text(
                        '${loaded.index + 1} / ${loaded.questions.length}',
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.cairo(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.onHeaderMuted,
                          lineHeight: 20,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: switch (state) {
              QuestionsLoading() => const AppLoadingView(),
              QuestionsError(:final message) => AppMessageView(
                message: message,
                onRetry: cubit.load,
              ),
              QuestionsLoaded() => _QuestionView(state),
            },
          ),
        );
      },
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView(this.state);

  final QuestionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuestionsCubit>();
    final question = state.current;
    final answer = state.currentAnswer;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionPrompt(question.question),
                const SizedBox(height: 28),
                for (final (index, option) in question.options.indexed) ...[
                  if (index > 0) const SizedBox(height: 14),
                  _AnswerOption(
                    label: option,
                    selected: option == answer,
                    onTap: () => cubit.selectAnswer(option),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 13, 24, 16),
            // The submission review follows the last question.
            child: ExamActionButton(
              label: 'التالي',
              onPressed: answer == null
                  ? null
                  : state.isLast
                  ? () => context.push(
                      RouteNames.studentExamReview(question.examId),
                      extra: cubit,
                    )
                  : cubit.next,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionPrompt extends StatelessWidget {
  const _QuestionPrompt(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AppColors.questionPromptBackground,
        border: Border.all(color: AppColors.lineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.cairo(
          size: 15,
          weight: FontWeight.w600,
          color: AppColors.title,
          lineHeight: 24.38,
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static final BorderRadius _radius = BorderRadius.circular(16);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: selected
              ? AppColors.optionSelectedBackground
              : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(
              color: selected
                  ? AppColors.optionSelectedBorder
                  : AppColors.optionBorder,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.cairo(
                        size: 15,
                        weight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected
                            ? AppColors.optionSelectedText
                            : AppColors.bodyText,
                        lineHeight: 22.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _OptionMark(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionMark extends StatelessWidget {
  const _OptionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.optionSelectedMark : null,
        border: selected
            ? null
            : Border.all(color: AppColors.optionMarkBorder, width: 2),
        shape: BoxShape.circle,
      ),
      child: selected ? SvgPicture.asset(AppAssets.optionCheckIcon) : null,
    );
  }
}
