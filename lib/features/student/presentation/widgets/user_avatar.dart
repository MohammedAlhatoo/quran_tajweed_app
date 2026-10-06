import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// The default avatar: a person icon on a dark circle.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    required this.iconSize,
    this.borderColor = AppColors.avatarBorder,
  });

  final double size;
  final double iconSize;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.avatarBackground,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: SvgPicture.asset(
        AppAssets.avatarIcon,
        width: iconSize,
        height: iconSize,
      ),
    );
  }
}
