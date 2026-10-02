import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The decorated Mushaf page frame around the Quran segment, with the page
/// number at the bottom.
class MushafFrame extends StatelessWidget {
  const MushafFrame({super.key, required this.page, required this.child});

  final int page;
  final Widget child;

  static const double _cornerInset = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mushafOutline),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.mushafPage,
          border: Border.all(color: AppColors.mushafBorder, width: 3),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.mushafInnerBorder),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFDFA), Color(0xFFFFFEFC), Color(0xFFFBF8EE)],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  children: [
                    Expanded(child: child),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.mushafFooterLine),
                        ),
                      ),
                      child: Text(
                        '$page',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cairo(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.mushafPageNumber,
                          lineHeight: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final alignment in const [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ])
                Positioned(
                  top: alignment.y < 0 ? _cornerInset : null,
                  bottom: alignment.y > 0 ? _cornerInset : null,
                  left: alignment.x < 0 ? _cornerInset : null,
                  right: alignment.x > 0 ? _cornerInset : null,
                  child: _Corner(alignment),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An L-shaped ornament hugging one corner of the page.
class _Corner extends StatelessWidget {
  const _Corner(this.alignment);

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.mushafCorner, width: 2);

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: alignment.y < 0 ? side : BorderSide.none,
          bottom: alignment.y > 0 ? side : BorderSide.none,
          left: alignment.x < 0 ? side : BorderSide.none,
          right: alignment.x > 0 ? side : BorderSide.none,
        ),
      ),
    );
  }
}
