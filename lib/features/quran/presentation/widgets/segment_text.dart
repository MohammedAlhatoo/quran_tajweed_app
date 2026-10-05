import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/quran_ayah.dart';

/// The characters [start] to [end] of the text of [ayah]: the part of the ayah
/// that lies on one Mushaf line. The parts of an ayah, joined in order, are
/// its text exactly.
@immutable
class MushafLinePiece {
  const MushafLinePiece(this.ayah, this.start, this.end);

  final QuranAyah ayah;
  final int start;
  final int end;

  String get text => ayah.text.substring(start, end);
}

/// One line of a Mushaf page, holding the parts of the ayahs written on it.
@immutable
class MushafLine {
  const MushafLine(this.page, this.line, this.pieces);

  final int page;
  final int line;
  final List<MushafLinePiece> pieces;
}

/// Lays [ayahs] out on the lines of their Mushaf pages, in the order given.
///
/// The data says on which line an ayah starts and on which it ends, but not
/// where the words of a longer ayah break. So an ayah always starts on its
/// `lineStart` and ends on its `lineEnd`, and the breaks in between are put
/// where the lines of the page come out closest in width, as [measure] gives
/// the width of a word. A line breaks only after a space of the text; the
/// space stays with the word before it.
///
/// Lines that hold no text of [ayahs], such as the heading of a surah, are
/// left out.
List<MushafLine> layOutMushafLines(
  List<QuranAyah> ayahs,
  double Function(String text) measure,
) {
  final lines = <MushafLine>[];
  var from = 0;
  for (var i = 1; i <= ayahs.length; i++) {
    // A run is the ayahs that follow one another down one page.
    final ends =
        i == ayahs.length ||
        ayahs[i].page != ayahs[i - 1].page ||
        ayahs[i].lineStart < ayahs[i - 1].lineEnd;
    if (ends) {
      lines.addAll(_layOutRun(ayahs.sublist(from, i), measure));
      from = i;
    }
  }
  return lines;
}

/// A word of an ayah with the space after it, and the lines it may lie on.
class _Word {
  const _Word(this.piece, this.firstLine, this.lastLine);

  final MushafLinePiece piece;
  final int firstLine;
  final int lastLine;
}

const int _space = 0x20;

List<_Word> _wordsOf(QuranAyah ayah) {
  final text = ayah.text;
  final starts = [
    0,
    for (var i = 1; i < text.length; i++)
      if (text.codeUnitAt(i - 1) == _space && text.codeUnitAt(i) != _space) i,
  ];
  return [
    for (var i = 0; i < starts.length; i++)
      _Word(
        MushafLinePiece(
          ayah,
          starts[i],
          i + 1 < starts.length ? starts[i + 1] : text.length,
        ),
        // The first word is on the first line of the ayah, the last word on
        // its last line.
        i == starts.length - 1 && i != 0 ? ayah.lineEnd : ayah.lineStart,
        i == 0 && starts.length != 1 ? ayah.lineStart : ayah.lineEnd,
      ),
  ];
}

List<MushafLine> _layOutRun(
  List<QuranAyah> run,
  double Function(String text) measure,
) {
  final page = run.first.page;
  final firstLine = run.first.lineStart;
  final lineCount = run.last.lineEnd - firstLine + 1;
  final words = [for (final ayah in run) ..._wordsOf(ayah)];

  // The width of the words before each word.
  final before = List<double>.filled(words.length + 1, 0);
  for (var i = 0; i < words.length; i++) {
    before[i + 1] = before[i] + measure(words[i].piece.text);
  }

  final hasText = List<bool>.filled(lineCount, false);
  for (final ayah in run) {
    for (var line = ayah.lineStart; line <= ayah.lineEnd; line++) {
      hasText[line - firstLine] = true;
    }
  }

  // cost[l][w]: the least sum of squared line widths with the first w words
  // on the first l lines. With the text and the lines fixed, the least sum is
  // the most even lines.
  final cost = [
    for (var l = 0; l <= lineCount; l++)
      List<double>.filled(words.length + 1, double.infinity),
  ];
  final cut = [
    for (var l = 0; l <= lineCount; l++) List<int>.filled(words.length + 1, 0),
  ];
  cost[0][0] = 0;
  for (var l = 0; l < lineCount; l++) {
    final line = firstLine + l;
    for (var start = 0; start <= words.length; start++) {
      final soFar = cost[l][start];
      if (soFar == double.infinity) continue;
      if (!hasText[l] && soFar < cost[l + 1][start]) {
        cost[l + 1][start] = soFar;
        cut[l + 1][start] = start;
      }
      for (var end = start + 1; end <= words.length; end++) {
        final word = words[end - 1];
        if (line < word.firstLine || line > word.lastLine) break;
        final width = before[end] - before[start];
        final total = soFar + width * width;
        if (total < cost[l + 1][end]) {
          cost[l + 1][end] = total;
          cut[l + 1][end] = start;
        }
      }
    }
  }

  // The first word of each line, from the last line back to the first.
  final starts = List<int>.filled(lineCount + 1, words.length);
  if (cost[lineCount][words.length] == double.infinity) {
    // An ayah with fewer words than lines, which the data does not have: one
    // word a line, the rest on the last line of the ayah.
    var word = 0;
    for (final ayah in run) {
      final count = _wordsOf(ayah).length;
      for (var i = 0; i < count; i++, word++) {
        final l = (ayah.lineStart + i).clamp(ayah.lineStart, ayah.lineEnd);
        for (var later = l - firstLine + 1; later <= lineCount; later++) {
          starts[later] = word + 1;
        }
      }
    }
    starts[0] = 0;
  } else {
    for (var l = lineCount; l > 0; l--) {
      starts[l - 1] = cut[l][starts[l]];
    }
  }

  final lines = <MushafLine>[];
  for (var l = 0; l < lineCount; l++) {
    final pieces = <MushafLinePiece>[];
    for (var i = starts[l]; i < starts[l + 1]; i++) {
      final piece = words[i].piece;
      // The words of one ayah on a line make one piece.
      if (pieces.isNotEmpty && identical(pieces.last.ayah, piece.ayah)) {
        pieces.last = MushafLinePiece(piece.ayah, pieces.last.start, piece.end);
      } else {
        pieces.add(piece);
      }
    }
    if (pieces.isNotEmpty) {
      lines.add(MushafLine(page, firstLine + l, List.unmodifiable(pieces)));
    }
  }
  return lines;
}

/// Shows [ayahs] as the Mushaf writes them: line by line, each ayah on the
/// lines the data gives it, in the font of the same source.
///
/// The text of an ayah is shown as it is, with the ayah mark it ends with.
/// Nothing is added but a space between two ayahs that share a line. The text
/// is made smaller when the widest line does not fit, and never wraps.
class SegmentText extends StatefulWidget {
  const SegmentText({super.key, required this.ayahs, this.style});

  final List<QuranAyah> ayahs;

  /// Defaults to [AppTextStyles.quran].
  final TextStyle? style;

  @override
  State<SegmentText> createState() => _SegmentTextState();
}

/// A line with the width of what is written on it in the style of the widget,
/// and how much wider that gets for each unit of word spacing.
class _MeasuredLine {
  const _MeasuredLine(this.line, this.width, this.gaps);

  final MushafLine line;
  final double width;
  final double gaps;
}

class _SegmentTextState extends State<SegmentText> {
  /// A line at least this much of the widest line is stretched to its width,
  /// as the lines of a Mushaf page are. A shorter line is centered.
  static const double _fullLine = 0.75;

  /// The most a space is widened to stretch a line, as a part of the font
  /// size. The Mushaf stretches a line by lengthening its letters, which the
  /// text is never changed to do, so a line that needs more stays shorter.
  static const double _widestStretch = 0.5;

  /// Between two ayahs on one line. It belongs to neither.
  static const String _ayahGap = ' ';

  late List<_MeasuredLine> _lines;

  TextStyle get _style => widget.style ?? AppTextStyles.quran;

  @override
  void initState() {
    super.initState();
    _lines = _measure();
  }

  @override
  void didUpdateWidget(SegmentText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.ayahs, oldWidget.ayahs) ||
        widget.style != oldWidget.style) {
      _lines = _measure();
    }
  }

  List<_MeasuredLine> _measure() {
    final style = _style;
    final spaced = style.copyWith(wordSpacing: 1);
    final painter = TextPainter(textDirection: TextDirection.rtl);

    double widthOf(InlineSpan span) {
      painter
        ..text = span
        ..layout();
      return painter.maxIntrinsicWidth;
    }

    final lines = [
      for (final line in layOutMushafLines(
        widget.ayahs,
        (text) => widthOf(TextSpan(text: text, style: style)),
      ))
        () {
          final width = widthOf(_span(line, style, toMeasure: true));
          return _MeasuredLine(
            line,
            width,
            widthOf(_span(line, spaced, toMeasure: true)) - width,
          );
        }(),
    ];
    painter.dispose();
    return lines;
  }

  /// The text of [line], each part of an ayah in a span of its own.
  ///
  /// A line that ends inside an ayah ends with the space of the break. It is
  /// shown as it is, and hangs past the end of the line as in any wrapped
  /// text. Only [toMeasure] leaves it out, to get the width of what is
  /// written; such a span is never shown.
  TextSpan _span(MushafLine line, TextStyle style, {bool toMeasure = false}) {
    final last = line.pieces.length - 1;
    return TextSpan(
      style: style,
      children: [
        for (final (i, piece) in line.pieces.indexed) ...[
          if (i > 0) const TextSpan(text: _ayahGap),
          TextSpan(
            text: toMeasure && i == last
                ? piece.text.substring(0, _writtenLength(piece.text))
                : piece.text,
          ),
        ],
      ],
    );
  }

  static int _writtenLength(String text) {
    var length = text.length;
    while (length > 0 && text.codeUnitAt(length - 1) == _space) {
      length--;
    }
    return length;
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final widest = _lines.fold<double>(
      0,
      (widest, line) => line.width > widest ? line.width : widest,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : widest;
          final scale = widest > width ? width / widest : 1.0;
          final fontSize = style.fontSize ?? AppTextStyles.quran.fontSize!;
          final fitted = style.copyWith(fontSize: fontSize * scale);
          // The widest line sets the width of the block, which the full
          // lines are stretched to.
          final block = widest * scale;

          return SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in _lines)
                  _line(
                    line,
                    fitted,
                    written: line.width * scale,
                    width: width,
                    wordSpacing: _stretches(line, widest)
                        ? ((block - line.width * scale) / line.gaps).clamp(
                            0.0,
                            fontSize * scale * _widestStretch,
                          )
                        : 0,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// One line, [written] wide before [wordSpacing] stretches it, centered in
  /// [width].
  Widget _line(
    _MeasuredLine line,
    TextStyle style, {
    required double written,
    required double width,
    required double wordSpacing,
  }) {
    return Padding(
      // The line is placed by its right end, where it starts, and not by the
      // text alignment: the space of a break hangs past the left end, and
      // the alignment would count it in.
      padding: EdgeInsets.only(
        right: math.max(0, (width - written - wordSpacing * line.gaps) / 2),
      ),
      child: OverflowBox(
        alignment: Alignment.centerRight,
        minWidth: 0,
        maxWidth: double.infinity,
        fit: OverflowBoxFit.deferToChild,
        child: Text.rich(
          _span(
            line.line,
            wordSpacing > 0 ? style.copyWith(wordSpacing: wordSpacing) : style,
          ),
          textDirection: TextDirection.rtl,
          textScaler: TextScaler.noScaling,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  bool _stretches(_MeasuredLine line, double widest) {
    return line.gaps > 0 &&
        line.width < widest &&
        line.width >= widest * _fullLine;
  }
}
