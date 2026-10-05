/// One ayah of the static Quran data in the app (Hafs 'an Asim, Madinah
/// Mushaf, 604 pages).
class QuranAyah {
  const QuranAyah({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.juz,
    required this.lineStart,
    required this.lineEnd,
    required this.text,
    required this.textEmlaey,
  });

  final int surah;
  final int ayah;
  final int page;
  final int juz;

  /// The first and the last line of the ayah on its page.
  final int lineStart;
  final int lineEnd;

  /// The ayah as the source writes it, ending with its ayah mark. It is never
  /// trimmed, normalized or changed in any way, and is shown only in the font
  /// of the same source.
  final String text;

  /// The ayah in plain spelling, for search only. It is never shown as Quran
  /// text.
  final String textEmlaey;

  /// Reads one entry of the source file, where the surah is named `sora`.
  ///
  /// Throws a [FormatException] when a field is missing or has another type.
  factory QuranAyah.fromMap(Map<String, dynamic> data) {
    return QuranAyah(
      surah: _field<int>(data, 'sora'),
      ayah: _field<int>(data, 'aya_no'),
      page: _field<int>(data, 'page'),
      juz: _field<int>(data, 'jozz'),
      lineStart: _field<int>(data, 'line_start'),
      lineEnd: _field<int>(data, 'line_end'),
      text: _field<String>(data, 'aya_text'),
      textEmlaey: _field<String>(data, 'aya_text_emlaey'),
    );
  }

  static T _field<T>(Map<String, dynamic> data, String name) {
    final value = data[name];
    if (value is T) return value;
    throw FormatException(
      value == null
          ? 'Quran data: the field "$name" is missing (id ${data['id']}).'
          : 'Quran data: the field "$name" is not of type $T '
                '(id ${data['id']}).',
    );
  }
}
