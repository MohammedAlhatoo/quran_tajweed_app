import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/repositories/quran_repository.dart';

/// Reads the Quran from the data file bundled with the app. The file is read
/// once, on the first request, and kept in memory.
class AssetQuranRepository implements QuranRepository {
  AssetQuranRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<_QuranIndex>? _index;

  @override
  Future<QuranAyah> ayah(int surah, int ayah) async {
    final index = await _load();
    return index.ayah(surah, ayah);
  }

  @override
  Future<List<QuranAyah>> ayahsOf(int surah, int from, int to) async {
    if (from < 1 || to < from) {
      throw QuranDataException(
        'The ayah range $from-$to of surah $surah is not valid.',
      );
    }
    final index = await _load();
    return List.unmodifiable([
      for (var ayah = from; ayah <= to; ayah++) index.ayah(surah, ayah),
    ]);
  }

  @override
  Future<List<QuranAyah>> ayahsOfPage(int page) async {
    final index = await _load();
    final ayahs = index.byPage[page];
    if (ayahs == null) {
      throw QuranDataException('The Quran data has no page $page.');
    }
    return List.unmodifiable(ayahs);
  }

  Future<_QuranIndex> _load() {
    // The future is kept, so requests made while the file is being read wait
    // for the same reading. A failed reading is not kept.
    return _index ??= _read().onError<Object>((error, stackTrace) {
      _index = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<_QuranIndex> _read() async {
    try {
      // cache: false, as the parsed data is what is kept, not the string.
      final source = await _bundle.loadString(
        AppAssets.quranData,
        cache: false,
      );
      final entries = jsonDecode(source);
      if (entries is! List) {
        throw const FormatException('Quran data: the file is not a list.');
      }

      final byReference = <(int, int), QuranAyah>{};
      final byPage = <int, List<QuranAyah>>{};
      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Quran data: an entry is not an object.');
        }
        final ayah = QuranAyah.fromMap(entry);
        final reference = (ayah.surah, ayah.ayah);
        if (byReference.containsKey(reference)) {
          throw FormatException(
            'Quran data: surah ${ayah.surah} ayah ${ayah.ayah} is repeated.',
          );
        }
        byReference[reference] = ayah;
        byPage.putIfAbsent(ayah.page, () => []).add(ayah);
      }
      return _QuranIndex(byReference, byPage);
    } on FormatException catch (e) {
      throw QuranDataException(e.message);
    } on FlutterError catch (e) {
      // The file is not in the bundle.
      throw QuranDataException(e.message);
    }
  }
}

/// The ayahs of the data file, by reference and by page.
class _QuranIndex {
  const _QuranIndex(this.byReference, this.byPage);

  final Map<(int, int), QuranAyah> byReference;
  final Map<int, List<QuranAyah>> byPage;

  QuranAyah ayah(int surah, int ayah) {
    final found = byReference[(surah, ayah)];
    if (found == null) {
      throw QuranDataException(
        'The Quran data has no ayah $ayah in surah $surah.',
      );
    }
    return found;
  }
}
