import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/app_assets.dart';
import 'package:quran_tajweed_app/core/theme/app_text_styles.dart';
import 'package:quran_tajweed_app/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran_tajweed_app/features/quran/presentation/widgets/segment_text.dart';

QuranAyah _ayah(
  int ayah,
  String text, {
  required int from,
  int? to,
  int page = 1,
}) => QuranAyah(
  surah: 1,
  ayah: ayah,
  page: page,
  juz: 1,
  lineStart: from,
  lineEnd: to ?? from,
  text: text,
  textEmlaey: 'plain $ayah',
);

/// A text with what a careless handling would change: spaces at both ends,
/// two spaces in a row, a non-breaking space before the ayah mark, and a
/// letter with a combining Hamza that NFC would compose.
const _fragileText = ' ألْ  بب جج دد ١ ';

/// Every character as wide as another.
double _byLength(String text) => text.length.toDouble();

/// The lines as [page, line, the texts of the pieces].
List<List<Object>> _plain(List<MushafLine> lines) => [
  for (final line in lines)
    [
      line.page,
      line.line,
      [for (final piece in line.pieces) piece.text],
    ],
];

/// The text of each ayah, as its pieces give it when joined in order.
Map<QuranAyah, String> _joined(List<MushafLine> lines) {
  final joined = <QuranAyah, String>{};
  for (final line in lines) {
    for (final piece in line.pieces) {
      joined[piece.ayah] = (joined[piece.ayah] ?? '') + piece.text;
    }
  }
  return joined;
}

Future<void> _pump(
  WidgetTester tester,
  List<QuranAyah> ayahs, {
  double width = 4000,
}) {
  return tester.pumpWidget(
    // The surroundings are left to right with a letter spacing, to show that
    // neither reaches the Quran text.
    Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Cairo', letterSpacing: 3),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: SegmentText(ayahs: ayahs)),
          ),
        ),
      ),
    ),
  );
}

/// The lines shown, top to bottom.
List<RichText> _shownLines(WidgetTester tester) =>
    tester.widgetList<RichText>(find.byType(RichText)).toList();

/// The span of a shown line that [SegmentText] builds: one child for each
/// piece of an ayah, with a space between two.
TextSpan _lineSpan(RichText line) =>
    (line.text as TextSpan).children!.single as TextSpan;

List<String> _spanTexts(RichText line) => [
  for (final span in _lineSpan(line).children!) (span as TextSpan).text!,
];

void main() {
  group('layOutMushafLines', () {
    test('keeps the order of the ayahs, each on its line', () {
      final lines = layOutMushafLines([
        _ayah(1, 'aa ١', from: 2),
        _ayah(2, 'bb ٢', from: 3),
        _ayah(3, 'cc ٣', from: 4),
      ], _byLength);

      expect(_plain(lines), [
        [
          1,
          2,
          ['aa ١'],
        ],
        [
          1,
          3,
          ['bb ٢'],
        ],
        [
          1,
          4,
          ['cc ٣'],
        ],
      ]);
    });

    test('puts the ayahs of one line on that line, each in its piece', () {
      final first = _ayah(3, 'aa ٣', from: 4);
      final second = _ayah(4, 'bb ٤', from: 4);

      final lines = layOutMushafLines([first, second], _byLength);

      expect(_plain(lines), [
        [
          1,
          4,
          ['aa ٣', 'bb ٤'],
        ],
      ]);
      expect(lines.single.pieces[0].ayah, same(first));
      expect(lines.single.pieces[1].ayah, same(second));
    });

    test('carries an ayah over all its lines, from the first to the last', () {
      final ayah = _ayah(7, 'aa bb cc dd ee ff ٧', from: 6, to: 8);

      final lines = layOutMushafLines([ayah], _byLength);

      expect([for (final line in lines) line.line], [6, 7, 8]);
      expect(_plain(lines), [
        [
          1,
          6,
          ['aa bb '],
        ],
        [
          1,
          7,
          ['cc dd '],
        ],
        [
          1,
          8,
          ['ee ff ٧'],
        ],
      ]);
      expect(_joined(lines)[ayah], ayah.text);
    });

    test('starts an ayah on the line where the one before it ends', () {
      final lines = layOutMushafLines([
        _ayah(5, 'aa ٥', from: 5),
        _ayah(6, 'bb cc ٦', from: 5, to: 6),
        _ayah(7, 'dd ee ٧', from: 6, to: 7),
      ], _byLength);

      expect(_plain(lines), [
        [
          1,
          5,
          ['aa ٥', 'bb '],
        ],
        [
          1,
          6,
          ['cc ٦', 'dd '],
        ],
        [
          1,
          7,
          ['ee ٧'],
        ],
      ]);
    });

    test('breaks a longer ayah where the lines come out most even', () {
      final lines = layOutMushafLines([
        _ayah(1, 'a bbbbbbbb cccc dddd ١', from: 1, to: 2),
      ], (text) => text.trimRight().length.toDouble());

      expect(_plain(lines), [
        [
          1,
          1,
          ['a bbbbbbbb '],
        ],
        [
          1,
          2,
          ['cccc dddd ١'],
        ],
      ]);
    });

    test('never breaks at the non-breaking space before the ayah mark', () {
      final lines = layOutMushafLines([
        _ayah(1, 'aa ١', from: 1, to: 2),
      ], _byLength);

      // One word for two lines: the data has no such ayah, and nothing of
      // the text is lost or split.
      expect(_plain(lines), [
        [
          1,
          1,
          ['aa ١'],
        ],
      ]);
    });

    test('gives the text of an ayah exactly, whatever it holds', () {
      final ayah = _ayah(1, _fragileText, from: 1, to: 3);

      final lines = layOutMushafLines([ayah], _byLength);

      expect(lines, hasLength(3));
      expect(_joined(lines)[ayah]!.codeUnits, _fragileText.codeUnits);
    });

    test('loses no word of an ayah with fewer words than lines', () {
      final ayah = _ayah(1, 'aa bb ١', from: 1, to: 4);

      final lines = layOutMushafLines([
        ayah,
        _ayah(2, 'cc ٢', from: 4),
      ], _byLength);

      expect(_joined(lines)[ayah], ayah.text);
      expect(lines.last.pieces.last.text, 'cc ٢');
    });

    test('leaves out the lines that hold no text of the ayahs', () {
      // The lines 3 and 4 are the heading of a surah and its Basmala.
      final lines = layOutMushafLines([
        _ayah(1, 'aa ١', from: 2),
        _ayah(2, 'bb ٢', from: 5),
      ], _byLength);

      expect([for (final line in lines) line.line], [2, 5]);
    });

    test('starts the lines again on a new page', () {
      final lines = layOutMushafLines([
        _ayah(1, 'aa bb ١', from: 14, to: 15),
        _ayah(2, 'cc ٢', from: 1, page: 2),
        _ayah(3, 'dd ٣', from: 1, page: 2),
      ], _byLength);

      expect(_plain(lines), [
        [
          1,
          14,
          ['aa '],
        ],
        [
          1,
          15,
          ['bb ١'],
        ],
        [
          2,
          1,
          ['cc ٢', 'dd ٣'],
        ],
      ]);
    });

    test('gives no line for no ayah', () {
      expect(layOutMushafLines(const [], _byLength), isEmpty);
    });
  });

  group('layOutMushafLines over the bundled Quran', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('keeps every ayah whole and on the lines the data gives it', () async {
      final source = await rootBundle.loadString(AppAssets.quranData);
      final ayahs = [
        for (final entry in jsonDecode(source) as List)
          QuranAyah.fromMap(entry as Map<String, dynamic>),
      ];

      final lines = layOutMushafLines(ayahs, _byLength);

      // The pieces follow the order of the data, and the lines go down the
      // pages.
      final pieces = [for (final line in lines) ...line.pieces];
      var index = 0;
      for (final piece in pieces) {
        if (!identical(piece.ayah, ayahs[index])) index++;
        expect(piece.ayah, same(ayahs[index]));
      }
      expect(index, ayahs.length - 1);
      for (var i = 1; i < lines.length; i++) {
        final before = lines[i - 1];
        expect(
          lines[i].page > before.page ||
              (lines[i].page == before.page && lines[i].line > before.line),
          isTrue,
          reason: 'page ${lines[i].page} line ${lines[i].line}',
        );
      }

      final joined = _joined(lines);
      final linesOf = <QuranAyah, List<int>>{};
      for (final line in lines) {
        for (final piece in line.pieces) {
          expect(line.page, piece.ayah.page);
          linesOf.putIfAbsent(piece.ayah, () => []).add(line.line);
        }
      }
      for (final ayah in ayahs) {
        final at = 'surah ${ayah.surah} ayah ${ayah.ayah}';
        expect(joined[ayah]!.codeUnits, ayah.text.codeUnits, reason: at);
        expect(linesOf[ayah], [
          for (var line = ayah.lineStart; line <= ayah.lineEnd; line++) line,
        ], reason: at);
      }
    });
  });

  group('AppTextStyles.quran', () {
    test('is the font of the source, with no letter spacing', () {
      const style = AppTextStyles.quran;

      expect(style.fontFamily, 'UthmanicHafs');
      expect(style.fontFamilyFallback, isNull);
      expect(style.letterSpacing, isNull);
      expect(style.inherit, isFalse);
    });
  });

  group('SegmentText', () {
    final ayahs = [
      _ayah(5, 'aa ٥', from: 5),
      _ayah(6, 'bb cc ٦', from: 5, to: 6),
      _ayah(7, _fragileText, from: 6, to: 8),
      _ayah(8, 'ee ٨', from: 1, page: 2),
    ];

    testWidgets('shows one line of text for each Mushaf line, in order', (
      tester,
    ) async {
      await _pump(tester, ayahs);

      final shown = _shownLines(tester);
      final lines = layOutMushafLines(ayahs, _byLength);
      expect(shown, hasLength(lines.length));
      expect(lines, hasLength(5));

      // Top to bottom, and never side by side.
      final tops = [
        for (final element in find.byType(RichText).evaluate())
          tester.getTopLeft(find.byWidget(element.widget)).dy,
      ];
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]));
      }
      for (final line in shown) {
        expect(line.softWrap, isFalse);
        expect(line.maxLines, 1);
      }
    });

    testWidgets('respects the first and the last line of every ayah', (
      tester,
    ) async {
      await _pump(tester, ayahs);

      final shown = [for (final line in _shownLines(tester)) _spanTexts(line)];
      // The line 5 holds the ayah 5 and the start of the ayah 6, the line 6
      // its end and the start of the ayah 7, which goes on to the line 8.
      expect(shown[0], ['aa ٥', ' ', 'bb ']);
      expect(shown[1].first, 'cc ٦');
      expect(shown[1], hasLength(3));
      expect(shown[2], hasLength(1));
      expect(shown[3], hasLength(1));
      expect(shown[4], ['ee ٨']);
      expect(
        (shown[1].last + shown[2].single + shown[3].single).codeUnits,
        _fragileText.codeUnits,
      );
    });

    testWidgets('shows the text of every ayah as it is, and nothing else', (
      tester,
    ) async {
      await _pump(tester, ayahs);

      // A span for each piece of an ayah, and only a space between two.
      final pieces = <String>[];
      for (final line in _shownLines(tester)) {
        final texts = _spanTexts(line);
        for (var i = 0; i < texts.length; i++) {
          if (i.isOdd) {
            expect(texts[i], ' ');
          } else {
            pieces.add(texts[i]);
          }
        }
      }

      expect(
        pieces.join().codeUnits,
        [for (final ayah in ayahs) ayah.text].join().codeUnits,
      );
    });

    testWidgets('keeps the ayahs apart, each piece in a span of its own', (
      tester,
    ) async {
      await _pump(tester, ayahs);

      final texts = [
        for (final line in _shownLines(tester))
          for (final (i, text) in _spanTexts(line).indexed)
            if (i.isEven) text,
      ];
      // Every ayah ends with its mark: no span holds text of two ayahs, and
      // the end of every ayah is in one span.
      const marks = ['٥', '٦', '١', '٨'];
      for (final text in texts) {
        expect(marks.where(text.contains).length, lessThanOrEqualTo(1));
      }
      for (final mark in marks) {
        expect(texts.where((text) => text.contains(mark)), hasLength(1));
      }
      expect(texts.first, 'aa ٥');
    });

    testWidgets('writes every line in UthmanicHafs, with no letter spacing', (
      tester,
    ) async {
      await _pump(tester, ayahs);

      for (final line in _shownLines(tester)) {
        final span = _lineSpan(line);
        expect(span.style!.fontFamily, 'UthmanicHafs');
        expect(span.style!.fontFamilyFallback, isNull);
        expect(span.style!.letterSpacing, isNull);
        // Nothing of the surrounding text style reaches the line.
        expect(span.style!.inherit, isFalse);
        for (final piece in span.children!) {
          expect(piece.style, isNull);
        }
      }
    });

    testWidgets('writes from right to left, whatever surrounds it', (
      tester,
    ) async {
      await _pump(tester, ayahs);

      for (final line in _shownLines(tester)) {
        expect(line.textDirection, TextDirection.rtl);
      }
      expect(
        Directionality.of(tester.element(find.byType(RichText).first)),
        TextDirection.rtl,
      );
    });

    testWidgets('makes the text smaller to fit, and never wraps a line', (
      tester,
    ) async {
      await _pump(tester, ayahs, width: 120);

      expect(tester.takeException(), isNull);
      final shown = _shownLines(tester);
      expect(shown, hasLength(5));
      final sizes = {for (final line in shown) _lineSpan(line).style!.fontSize};
      expect(sizes, hasLength(1));
      expect(sizes.single, lessThan(AppTextStyles.quran.fontSize!));
    });

    testWidgets('shows the new ayahs when they change', (tester) async {
      await _pump(tester, ayahs);
      await _pump(tester, [_ayah(1, 'zz ١', from: 2)]);

      expect(
        [for (final line in _shownLines(tester)) _spanTexts(line)],
        [
          ['zz ١'],
        ],
      );
    });

    testWidgets('shows nothing for no ayah', (tester) async {
      await _pump(tester, const []);

      expect(tester.takeException(), isNull);
      expect(find.byType(RichText), findsNothing);
    });
  });
}
