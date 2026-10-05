import '../entities/quran_ayah.dart';

/// The Quran data cannot be read, or does not hold what was asked for.
class QuranDataException implements Exception {
  const QuranDataException(this.message);

  final String message;

  @override
  String toString() => 'QuranDataException: $message';
}

/// Reads the static Quran data in the app.
///
/// All methods throw [QuranDataException] on error. They never return a part
/// of what was asked for.
abstract interface class QuranRepository {
  /// The ayah [ayah] of the surah [surah].
  Future<QuranAyah> ayah(int surah, int ayah);

  /// The ayahs [from] to [to] of the surah [surah], both included, in order.
  Future<List<QuranAyah>> ayahsOf(int surah, int from, int to);

  /// The ayahs that start on the page [page], in Mushaf order.
  Future<List<QuranAyah>> ayahsOfPage(int page);
}
