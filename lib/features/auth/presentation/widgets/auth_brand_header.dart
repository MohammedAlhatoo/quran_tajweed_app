import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Logo, app name and a subtitle line.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    this.subtitle = AppConstants.appTagline,
    this.logoSize = 96,
  });

  final String subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(AppAssets.logo, width: logoSize, height: logoSize),
        const SizedBox(height: 12),
        Text(
          AppConstants.appName,
          style: AppTextStyles.heading,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTextStyles.subtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
