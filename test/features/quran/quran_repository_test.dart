import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/app_assets.dart';
import 'package:quran_tajweed_app/features/quran/data/repositories/asset_quran_repository.dart';
import 'package:quran_tajweed_app/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran_tajweed_app/features/quran/domain/repositories/quran_repository.dart';

/// Serves [source] as the Quran data file and counts its readings.
class _FakeBundle extends AssetBundle {
  _FakeBundle(this.source);

  final String source;
  int readings = 0;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(key, AppAssets.quranData);
    readings++;
    return source;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => throw UnimplementedError();
}

/// A text with what a careless reading would change: spaces at both ends, a
/// non-breaking space before the ayah mark, and a letter with a combining
/// Hamza that NFC would compose.
const _fragileText = ' ألْ  ب ١ ';

Map<String, dynamic> _entry(
  int surah,
  int ayah, {
  int page = 1,
  String? text,
}) => {
  'id': surah * 1000 + ayah,
  'jozz': 1,
  'sora': surah,
  'sora_name_en': 'Name',
  'sora_name_ar': 'اسم',
  'page': page,
  'line_start': 2,
  'line_end': 3,
  'aya_no': ayah,
  'aya_text': text ?? 'text $surah:$ayah',
  'aya_text_emlaey': 'plain $surah:$ayah',
};

final _entries = [
  _entry(1, 1, text: _fragileText),
  _entry(1, 2),
  _entry(1, 3, page: 2),
  _entry(2, 1, page: 2),
  _entry(2, 2, page: 3),
];

(AssetQuranRepository, _FakeBundle) _repository([Object? data]) {
  final bundle = _FakeBundle(jsonEncode(data ?? _entries));
  return (AssetQuranRepository(bundle: bundle), bundle);
}

final _throwsQuranData = throwsA(isA<QuranDataException>());

void main() {
  group('QuranAyah.fromMap', () {
    test('reads the fields of the source, the surah from `sora`', () {
      final ayah = QuranAyah.fromMap({
        'id': 8,
        'jozz': 3,
        'sora': 2,
        'sora_name_en': 'Al-Baqarah',
        'sora_name_ar': 'البَقَرَة',
        'page': 42,
        'line_start': 5,
        'line_end': 7,
        'aya_no': 255,
        'aya_text': 'نص',
        'aya_text_emlaey': 'نص املائي',
      });

      expect(ayah.surah, 2);
      expect(ayah.ayah, 255);
      expect(ayah.page, 42);
      expect(ayah.juz, 3);
      expect(ayah.lineStart, 5);
      expect(ayah.lineEnd, 7);
      expect(ayah.text, 'نص');
      expect(ayah.textEmlaey, 'نص املائي');
    });

    test('keeps the text exactly as the source writes it', () {
      final ayah = QuranAyah.fromMap(_entry(1, 1, text: _fragileText));

      expect(ayah.text.codeUnits, _fragileText.codeUnits);
    });

    test('throws on a missing field, naming it', () {
      for (final name in [
        'jozz',
        'sora',
        'page',
        'line_start',
        'line_end',
        'aya_no',
        'aya_text',
        'aya_text_emlaey',
      ]) {
        final data = _entry(1, 1)..remove(name);
        expect(
          () => QuranAyah.fromMap(data),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('"$name"'),
            ),
          ),
          reason: name,
        );
      }
    });

    test('throws on a field of another type', () {
      expect(
        () => QuranAyah.fromMap(_entry(1, 1)..['sora'] = '1'),
        throwsFormatException,
      );
      expect(
        () => QuranAyah.fromMap(_entry(1, 1)..['page'] = 1.5),
        throwsFormatException,
      );
      expect(
        () => QuranAyah.fromMap(_entry(1, 1)..['aya_text'] = 7),
        throwsFormatException,
      );
    });

    test('does not read the surah from `sora_no`', () {
      final data = _entry(1, 1)
        ..remove('sora')
        ..['sora_no'] = 1;
      expect(() => QuranAyah.fromMap(data), throwsFormatException);
    });
  });

  group('AssetQuranRepository', () {
    test('ayah returns the ayah of a surah', () async {
      final (repository, _) = _repository();

      final ayah = await repository.ayah(2, 1);

      expect(ayah.surah, 2);
      expect(ayah.ayah, 1);
      expect(ayah.page, 2);
      expect(ayah.text, 'text 2:1');
    });

    test('ayah keeps the text exactly as the file writes it', () async {
      final (repository, _) = _repository();

      final ayah = await repository.ayah(1, 1);

      expect(ayah.text.codeUnits, _fragileText.codeUnits);
    });

    test('ayah throws when the ayah does not exist', () async {
      final (repository, _) = _repository();

      await expectLater(repository.ayah(1, 4), _throwsQuranData);
      await expectLater(repository.ayah(3, 1), _throwsQuranData);
    });

    test('ayahsOf returns the ayahs of the range in order', () async {
      final (repository, _) = _repository();

      final ayahs = await repository.ayahsOf(1, 2, 3);
      final one = await repository.ayahsOf(1, 1, 1);

      expect([for (final ayah in ayahs) ayah.ayah], [2, 3]);
      expect(ayahs.every((ayah) => ayah.surah == 1), isTrue);
      expect(one.single.ayah, 1);
    });

    test('ayahsOf throws when an ayah of the range does not exist', () async {
      final (repository, _) = _repository();

      await expectLater(repository.ayahsOf(1, 2, 4), _throwsQuranData);
      await expectLater(repository.ayahsOf(9, 1, 2), _throwsQuranData);
    });

    test('ayahsOf throws on a range that is not valid', () async {
      final (repository, _) = _repository();

      await expectLater(repository.ayahsOf(1, 3, 2), _throwsQuranData);
      await expectLater(repository.ayahsOf(1, 0, 2), _throwsQuranData);
    });

    test('ayahsOfPage returns the ayahs of the page in order', () async {
      final (repository, _) = _repository();

      final ayahs = await repository.ayahsOfPage(2);

      expect(
        [for (final ayah in ayahs) (ayah.surah, ayah.ayah)],
        [(1, 3), (2, 1)],
      );
    });

    test('ayahsOfPage throws when the page does not exist', () async {
      final (repository, _) = _repository();

      await expectLater(repository.ayahsOfPage(4), _throwsQuranData);
    });

    test('reads the file once', () async {
      final (repository, bundle) = _repository();
      expect(bundle.readings, 0);

      await Future.wait([
        repository.ayah(1, 1),
        repository.ayahsOf(1, 1, 3),
        repository.ayahsOfPage(2),
      ]);
      await repository.ayah(2, 2);
      await expectLater(repository.ayah(9, 9), _throwsQuranData);

      expect(bundle.readings, 1);
    });

    test('throws when an entry misses a field', () async {
      final (repository, _) = _repository([
        _entry(1, 1),
        _entry(1, 2)..remove('aya_text'),
      ]);

      await expectLater(repository.ayah(1, 1), _throwsQuranData);
    });

    test('throws when an ayah is repeated', () async {
      final (repository, _) = _repository([_entry(1, 1), _entry(1, 1)]);

      await expectLater(repository.ayah(1, 1), _throwsQuranData);
    });

    test('throws when the file is not a list of entries', () async {
      final (notList, _) = _repository({'sora': 1});
      final (notObjects, _) = _repository([1, 2]);
      final notJson = AssetQuranRepository(bundle: _FakeBundle('not json'));

      await expectLater(notList.ayah(1, 1), _throwsQuranData);
      await expectLater(notObjects.ayah(1, 1), _throwsQuranData);
      await expectLater(notJson.ayah(1, 1), _throwsQuranData);
    });
  });

  group('AssetQuranRepository over the bundled file', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('gives every text exactly as the file writes it', () async {
      final repository = AssetQuranRepository();
      final source = await rootBundle.loadString(AppAssets.quranData);
      final entries = (jsonDecode(source) as List).cast<Map<String, dynamic>>();

      for (final entry in entries) {
        final ayah = await repository.ayah(
          entry['sora'] as int,
          entry['aya_no'] as int,
        );
        expect(
          ayah.text.codeUnits,
          (entry['aya_text'] as String).codeUnits,
          reason: 'id ${entry['id']}',
        );
      }
    });
  });
}
