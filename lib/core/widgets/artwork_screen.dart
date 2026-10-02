import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A full-screen design exported as one image.
///
/// The export carries a shadow and an empty margin around the screen, so only
/// [frame] is shown. It fills the screen, cropping what does not fit, but is
/// never enlarged so far that [keep] is cut; [backdrop] fills what is left.
/// [children] are placed over the image in the image's own pixels.
class ArtworkScreen extends StatelessWidget {
  const ArtworkScreen({
    super.key,
    required this.asset,
    required this.imageSize,
    required this.frame,
    required this.keep,
    required this.backdrop,
    required this.semanticLabel,
    this.alignment = Alignment.center,
    this.extendSides = false,
    this.children = const [],
  });

  /// The width of the column taken from each side of [frame], and how far
  /// inside the frame it is taken, in the image's pixels.
  static const double _sideWidth = 2;
  static const double _sideInset = 2;

  final String asset;

  /// The size of the image file in pixels.
  final Size imageSize;

  /// The part of the image that holds the screen.
  final Rect frame;

  /// How much of [frame], measured from [alignment], must stay visible.
  final Size keep;

  /// Top-to-bottom colors that continue the image beyond its edges.
  final List<Color> backdrop;

  final String semanticLabel;
  final Alignment alignment;

  /// Whether the space left beside the image continues the image's own side
  /// colors, row by row, instead of showing [backdrop].
  final bool extendSides;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The artwork is dark, so the status bar icons are light.
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backdrop,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screen = constraints.biggest;
            final cover = math.max(
              screen.width / frame.width,
              screen.height / frame.height,
            );
            final fit = math.min(
              screen.width / keep.width,
              screen.height / keep.height,
            );
            final scale = math.min(cover, fit);

            final artwork = ClipRect(
              child: OverflowBox(
                alignment: alignment,
                minWidth: frame.width * scale,
                maxWidth: frame.width * scale,
                minHeight: frame.height * scale,
                maxHeight: frame.height * scale,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox.fromSize(
                    size: frame.size,
                    child: Stack(
                      children: [
                        Positioned(
                          left: -frame.left,
                          top: -frame.top,
                          width: imageSize.width,
                          height: imageSize.height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  asset,
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.medium,
                                  semanticLabel: semanticLabel,
                                ),
                              ),
                              ...children,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            final shown = alignment.inscribe(
              frame.size * scale,
              Offset.zero & screen,
            );
            if (!extendSides || shown.width >= screen.width) return artwork;

            // They reach one pixel under the image so that no seam shows.
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fromRect(
                  rect: Rect.fromLTRB(
                    0,
                    shown.top,
                    shown.left + 1,
                    shown.bottom,
                  ),
                  child: _side(frame.left + _sideInset),
                ),
                Positioned.fromRect(
                  rect: Rect.fromLTRB(
                    shown.right - 1,
                    shown.top,
                    screen.width,
                    shown.bottom,
                  ),
                  child: _side(frame.right - _sideInset - _sideWidth),
                ),
                artwork,
              ],
            );
          },
        ),
      ),
    );
  }

  /// The image's column of pixels at [x], stretched to the space it is given.
  Widget _side(double x) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: _sideWidth,
        height: frame.height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: imageSize.width,
            maxWidth: imageSize.width,
            minHeight: imageSize.height,
            maxHeight: imageSize.height,
            child: Transform.translate(
              offset: Offset(-x, -frame.top),
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
