import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/artwork_screen.dart';

/// Shown while the saved session is being checked.
///
/// The background is there from the first frame. The logo, the name and the
/// title slide in from above while the tagline and the description slide in
/// from below, all at once, and then stay where the design puts them.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _entrance = Duration(milliseconds: 600);

  /// How far each group starts from its place, in the image's pixels. Each is
  /// a little more than the group's distance from the edge it enters from, so
  /// that it starts out of sight.
  static const double _topTravel = 560;
  static const double _bottomTravel = 840;

  // Where the design draws each piece, in the image's pixels, which are twice
  // the design's points.
  static const Rect _logo = Rect.fromLTWH(306, 90, 320, 320);
  static const Rect _brand = Rect.fromLTWH(291, 394, 352, 88);
  static const Rect _tagline = Rect.fromLTWH(234, 923, 464, 146);
  static const Rect _description = Rect.fromLTWH(140, 1496, 652, 106);

  /// The title file holds the text on two lines, the second one centered
  /// under the first. The design has it on one line, so each line is shown on
  /// its own: the first on the right and the second moved up beside it.
  static const Size _titleSize = Size(374, 78);
  static const Rect _titleFirstLine = Rect.fromLTWH(350, 487, 374, 38);
  static const Rect _titleSecondLine = Rect.fromLTWH(86, 487, 374, 40);
  static const double _titleSecondLineTop = 39;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _entrance,
  );
  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  bool _precached = false;

  @override
  void initState() {
    super.initState();
    // Started once the first frame is on screen, so that the time it takes to
    // draw that frame is not taken out of the movement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArtworkScreen(
        asset: AppAssets.splashBackground,
        imageSize: const Size(932, 1856),
        frame: const Rect.fromLTRB(76, 26, 856, 1730),
        // From the logo down to the last line of text, with room for the
        // status and navigation bars.
        keep: const Size(660, 1600),
        backdrop: AppColors.splashBackdrop,
        // The design's sides are plain, so they are continued on a screen
        // wider than the design.
        extendSides: true,
        semanticLabel: '${AppConstants.appName}، ${AppConstants.appTagline}',
        children: [
          _SlideIn(
            animation: _slide,
            travel: -_topTravel,
            children: [
              _piece(_logo, AppAssets.splashLogo),
              _piece(_brand, AppAssets.splashBrand),
              _titleLine(_titleFirstLine, 0),
              _titleLine(_titleSecondLine, _titleSecondLineTop),
            ],
          ),
          _SlideIn(
            animation: _slide,
            travel: _bottomTravel,
            children: [
              _piece(_tagline, AppAssets.splashTagline),
              _piece(_description, AppAssets.splashDescription),
            ],
          ),
        ],
      ),
    );
  }

  Widget _piece(Rect rect, String asset) {
    return Positioned.fromRect(
      rect: rect,
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.fill,
        excludeFromSemantics: true,
      ),
    );
  }

  /// The part of the title that starts [top] below the title's own top edge,
  /// shown in [rect] and cut at its edges.
  Widget _titleLine(Rect rect, double top) {
    return Positioned.fromRect(
      rect: rect,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: -top,
            width: _titleSize.width,
            height: _titleSize.height,
            child: SvgPicture.asset(
              AppAssets.splashTitle,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Moves [children] together from [travel] pixels away, measured downwards,
/// to their own places as [animation] runs.
class _SlideIn extends StatelessWidget {
  const _SlideIn({
    required this.animation,
    required this.travel,
    required this.children,
  });

  final Animation<double> animation;
  final double travel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, travel * (1 - animation.value)),
          child: child,
        ),
        child: Stack(children: children),
      ),
    );
  }
}
