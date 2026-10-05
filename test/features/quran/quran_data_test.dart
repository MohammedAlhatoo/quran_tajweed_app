import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/app_assets.dart';
import 'package:quran_tajweed_app/features/quran/domain/entities/quran_ayah.dart';

/// The number of ayahs of each of the 114 surahs, in Mushaf order.
const _ayahCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, //
  111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, //
  54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, //
  49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, //
  44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, //
  26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, //
  6, 3, 5, 4, 5, 6,
];

/// Checks the bundled Quran data file as it is. A failure here is reported,
/// never fixed by changing the file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> entries;
  late List<QuranAyah> ayahs;

  setUpAll(() async {
    final source = await rootBundle.loadString(AppAssets.quranData);
    entries = (jsonDecode(source) as List).cast<Map<String, dynamic>>();
    ayahs = [for (final entry in entries) QuranAyah.fromMap(entry)];
  });

  String at(int index) =>
      'id ${entries[index]['id']} '
      '(surah ${ayahs[index].surah}, ayah ${ayahs[index].ayah})';

  test('holds 6236 ayahs, every one read by QuranAyah', () {
    expect(entries, hasLength(6236));
    expect(ayahs, hasLength(6236));
  });

  test('numbers its entries from 1 to 6236 in order', () {
    for (var i = 0; i < entries.length; i++) {
      expect(entries[i]['id'], i + 1, reason: 'entry ${i + 1}');
    }
  });

  test('holds the 114 surahs in order, each with all its ayahs', () {
    expect(_ayahCounts, hasLength(114));
    expect(_ayahCounts.reduce((a, b) => a + b), 6236);

    var index = 0;
    for (var surah = 1; surah <= 114; surah++) {
      for (var ayah = 1; ayah <= _ayahCounts[surah - 1]; ayah++) {
        expect(index, lessThan(ayahs.length), reason: 'surah $surah');
        expect(ayahs[index].surah, surah, reason: at(index));
        expect(ayahs[index].ayah, ayah, reason: at(index));
        index++;
      }
    }
    expect(index, ayahs.length);
    expect({for (final ayah in ayahs) ayah.surah}, hasLength(114));
  });

  test('covers the pages 1 to 604, never going back', () {
    expect(ayahs.first.page, 1);
    expect(ayahs.last.page, 604);
    for (var i = 1; i < ayahs.length; i++) {
      expect(
        ayahs[i].page,
        greaterThanOrEqualTo(ayahs[i - 1].page),
        reason: at(i),
      );
    }
    expect({for (final ayah in ayahs) ayah.page}, {
      for (var page = 1; page <= 604; page++) page,
    });
  });

  test('covers the Juz 1 to 30, never going back', () {
    expect(ayahs.first.juz, 1);
    expect(ayahs.last.juz, 30);
    for (var i = 1; i < ayahs.length; i++) {
      expect(
        ayahs[i].juz,
        greaterThanOrEqualTo(ayahs[i - 1].juz),
        reason: at(i),
      );
    }
    expect({for (final ayah in ayahs) ayah.juz}, {
      for (var juz = 1; juz <= 30; juz++) juz,
    });
  });

  test('gives every ayah lines of its page, the first before the last', () {
    for (var i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      expect(ayah.lineStart, inInclusiveRange(1, 15), reason: at(i));
      expect(ayah.lineEnd, inInclusiveRange(1, 15), reason: at(i));
      expect(
        ayah.lineEnd,
        greaterThanOrEqualTo(ayah.lineStart),
        reason: at(i),
      );
    }
  });

  test('has no empty text', () {
    for (var i = 0; i < ayahs.length; i++) {
      expect(ayahs[i].text, isNotEmpty, reason: at(i));
      expect(ayahs[i].textEmlaey, isNotEmpty, reason: at(i));
    }
  });
}
