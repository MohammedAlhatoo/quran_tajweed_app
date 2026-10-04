import 'dart:math';

import '../../../courses/domain/entities/course_level.dart';

/// The definition of one `exam_segments` document.
///
/// It holds the reference of the segment only, never its text.
class ExamSegmentSeed {
  const ExamSegmentSeed(
    this.surah,
    this.ayahFrom,
    this.ayahTo,
    this.page,
    this.ruleDensity,
    this.ruleIds, {
    this.from = CourseLevel.introductory,
  });

  final int surah;
  final int ayahFrom;
  final int ayahTo;

  /// The page of the Madinah Mushaf that holds the whole segment.
  final int page;

  /// The places of the rules of [ruleIds] in the segment, per word.
  final double ruleDensity;

  /// The Tajweed rules that have a place in the segment, from
  /// `tajweed_rules`. A rule that applies to every letter, or that depends on
  /// where the reader stops, is not listed.
  final List<String> ruleIds;

  /// The first course level the segment is given in. Every higher level is
  /// given it too.
  ///
  /// It is above the introductory level only when the segment holds a place
  /// that cannot be read correctly without having been taught it. A rule of
  /// a higher course that is read as the Mushaf writes it, such as the Alif
  /// of «أنا», is listed in [ruleIds] and leaves the segment open to every
  /// course.
  final CourseLevel from;

  /// The document ID. It is permanent: examinations refer to it.
  String get id => 's${_pad(surah)}_${_pad(ayahFrom)}_${_pad(ayahTo)}';

  /// The levels of the courses the segment is given in.
  List<CourseLevel> get levels => [
    for (final level in CourseLevel.values)
      if (level.index >= from.index) level,
  ];

  /// From 1 (easy) to 3 (hard). It follows [from].
  int get difficulty => min(from.index + 1, 3);

  /// The fields of the `exam_segments` document, without `isActive` and
  /// `createdAt`.
  Map<String, Object?> toMap({
    required List<String> ruleIds,
    required List<String> courseIds,
  }) => {
    'surah': surah,
    'ayahFrom': ayahFrom,
    'ayahTo': ayahTo,
    'page': page,
    'ruleIds': ruleIds,
    'courseIds': courseIds,
    'difficulty': difficulty,
    'ruleDensity': ruleDensity,
  };

  static String _pad(int number) => number.toString().padLeft(3, '0');
}
