import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// The back button used as the leading widget of an app bar.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// Replaces leaving the screen, for a screen with steps of its own.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'الرجوع',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: SvgPicture.asset(
        AppAssets.backIcon,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(
          AppColors.onHeader,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
