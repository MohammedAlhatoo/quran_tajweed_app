import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';

/// The back button used as the leading widget of an app bar.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'الرجوع',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: SvgPicture.asset(AppAssets.backIcon, width: 20, height: 20),
    );
  }
}
