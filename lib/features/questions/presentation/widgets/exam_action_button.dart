import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The full-width action button of the theory questions flow.
class ExamActionButton extends StatelessWidget {
  const ExamActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: onPressed == null && !isLoading
            ? null
            : const [
                BoxShadow(
                  color: AppColors.questionsActionShadow,
                  offset: Offset(0, 4),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: AppColors.questionsActionShadow,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.questionsAction,
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
