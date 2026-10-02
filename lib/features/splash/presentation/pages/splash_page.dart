import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/artwork_screen.dart';

/// Shown while the saved session is being checked.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // The onboarding opens next for a signed-out user; its image is decoded
    // now so that it does not appear late.
    precacheImage(const AssetImage(AppAssets.onboardingArtwork), context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ArtworkScreen(
        asset: AppAssets.splashArtwork,
        imageSize: Size(932, 1856),
        frame: Rect.fromLTRB(76, 26, 856, 1730),
        // From the logo down to the last line of text, with room for the
        // status and navigation bars.
        keep: Size(660, 1600),
        backdrop: AppColors.splashBackdrop,
        // The design's sides are plain, so they are continued on a screen
        // wider than the design.
        extendSides: true,
        semanticLabel: '${AppConstants.appName}، ${AppConstants.appTagline}',
      ),
    );
  }
}
