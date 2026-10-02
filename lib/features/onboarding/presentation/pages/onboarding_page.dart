import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/artwork_screen.dart';

/// The first screen of a signed-out launch. It leads to the login page.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onStart});

  /// Called when the start button is pressed.
  final VoidCallback onStart;

  /// Where the design draws the button, in the image's pixels.
  static const Rect _startButton = Rect.fromLTRB(140, 1492, 820, 1600);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArtworkScreen(
        asset: AppAssets.onboardingArtwork,
        imageSize: const Size(960, 1868),
        // Slightly inside the exported screen, to leave out its rounded top
        // corners.
        frame: const Rect.fromLTRB(102, 84, 858, 1728),
        // From the dome down to the button, which is anchored to the bottom.
        keep: const Size(720, 1100),
        alignment: Alignment.bottomCenter,
        backdrop: AppColors.onboardingBackdrop,
        semanticLabel: '${AppConstants.appName}، ${AppConstants.appTagline}',
        children: [
          Positioned.fromRect(
            rect: _startButton,
            child: _StartButton(onTap: onStart),
          ),
        ],
      ),
    );
  }
}

/// Sized in the image's pixels, which are twice the design's points.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      side: BorderSide(color: AppColors.onboardingActionBorder, width: 2),
    );

    return Semantics(
      button: true,
      child: Material(
        color: AppColors.onboardingAction,
        shape: shape,
        elevation: 6,
        shadowColor: Colors.black,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ابدأ الآن',
                style: AppTextStyles.cairo(
                  size: 36,
                  weight: FontWeight.w700,
                  color: AppColors.onPrimary,
                  lineHeight: 48,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.chevron_left,
                size: 48,
                color: AppColors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
