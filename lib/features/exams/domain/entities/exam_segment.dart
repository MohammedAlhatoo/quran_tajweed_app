/// A predefined Quran segment from the `exam_segments` collection. It holds
/// only the reference; the text comes from the static Quran data in the app.
class ExamSegment {
  const ExamSegment({
    required this.id,
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    required this.page,
    required this.ruleIds,
    required this.courseIds,
    required this.ruleDensity,
    required this.isActive,
  });

  final String id;
  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final int page;
  final List<String> ruleIds;
  final List<String> courseIds;
  final double ruleDensity;
  final bool isActive;

  /// Returns null when the reference is missing or outside the Mushaf.
  static ExamSegment? fromMap(String id, Map<String, dynamic> data) {
    final surah = data['surah'];
    final ayahFrom = data['ayahFrom'];
    final ayahTo = data['ayahTo'];
    final page = data['page'];
    if (surah is! int || surah < 1 || surah > 114) return null;
    if (ayahFrom is! int || ayahTo is! int) return null;
    if (ayahFrom < 1 || ayahTo < ayahFrom) return null;
    if (page is! int || page < 1 || page > 604) return null;

    final ruleDensity = data['ruleDensity'];
    return ExamSegment(
      id: id,
      surah: surah,
      ayahFrom: ayahFrom,
      ayahTo: ayahTo,
      page: page,
      ruleIds: _strings(data['ruleIds']),
      courseIds: _strings(data['courseIds']),
      ruleDensity: ruleDensity is num ? ruleDensity.toDouble() : 0,
      isActive: data['isActive'] == true,
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
