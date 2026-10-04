import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/firebase_collections.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seed.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/exams/data/seed/exam_segment_seed.dart';
import 'package:quran_tajweed_app/features/exams/data/seed/exam_segments_seed.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/segment_selector.dart';

class _MemorySeedStore implements SeedStore {
  final Map<String, Map<String, Map<String, dynamic>>> collections = {};

  @override
  Object get timestamp => 'now';

  Map<String, Map<String, dynamic>> docs(String collection) =>
      collections.putIfAbsent(collection, () => {});

  @override
  Future<Map<String, Map<String, dynamic>>> readAll(
    String collection,
  ) async => {
    for (final entry in docs(collection).entries) entry.key: {...entry.value},
  };

  @override
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  ) async {
    for (final entry in documents.entries) {
      docs(collection).putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }
}

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

final _rules = {for (final rule in tajweedRuleSeeds) rule.id: rule};

/// The `exam_segments` documents, as the app reads them.
List<ExamSegment> _segments() => [
  for (final seed in examSegmentSeeds)
    ExamSegment.fromMap(seed.id, {
      ...seed.toMap(
        ruleIds: seed.ruleIds,
        courseIds: [for (final level in seed.levels) level.value],
      ),
      'isActive': true,
    })!,
];

/// The weights of the rules of the course of [level], as `course_rules`
/// holds them.
Map<String, double> _weightsOf(CourseLevel level) => {
  for (final link in courseRuleSeeds)
    if (link.level == level) link.ruleId: link.weight.toDouble(),
};

void main() {
  group('ExamSegment.fromMap', () {
    const reference = {'surah': 2, 'ayahFrom': 6, 'ayahTo': 10, 'page': 3};

    test('reads the difficulty', () {
      final segment = ExamSegment.fromMap('s1', {
        ...reference,
        'difficulty': 3,
      })!;
      expect(segment.difficulty, 3);
    });

    test('reads a missing difficulty as 1', () {
      expect(ExamSegment.fromMap('s1', reference)!.difficulty, 1);
    });
  });

  group('exam segments', () {
    test('cover the Mushaf from its first Juz to its last', () {
      expect(examSegmentSeeds.length, greaterThan(150));
      expect(examSegmentSeeds.first.page, lessThan(10));
      expect(examSegmentSeeds.last.page, greaterThan(595));
    });

    test('have no duplicate IDs', () {
      expect({
        for (final seed in examSegmentSeeds) seed.id,
      }, hasLength(examSegmentSeeds.length));
    });

    test('refer to ayahs that exist', () {
      expect(_ayahCounts, hasLength(114));
      for (final seed in examSegmentSeeds) {
        expect(seed.surah, inInclusiveRange(1, 114), reason: seed.id);
        expect(seed.ayahFrom, greaterThanOrEqualTo(1), reason: seed.id);
        expect(
          seed.ayahTo,
          greaterThanOrEqualTo(seed.ayahFrom),
          reason: seed.id,
        );
        expect(
          seed.ayahTo,
          lessThanOrEqualTo(_ayahCounts[seed.surah - 1]),
          reason: seed.id,
        );
        expect(seed.page, inInclusiveRange(1, 604), reason: seed.id);
      }
    });

    test('are in Mushaf order and never overlap', () {
      for (var i = 1; i < examSegmentSeeds.length; i++) {
        final previous = examSegmentSeeds[i - 1];
        final seed = examSegmentSeeds[i];
        expect(seed.page, greaterThanOrEqualTo(previous.page), reason: seed.id);
        if (seed.surah == previous.surah) {
          expect(seed.ayahFrom, greaterThan(previous.ayahTo), reason: seed.id);
        } else {
          expect(seed.surah, greaterThan(previous.surah), reason: seed.id);
        }
      }
    });

    test('are linked only to existing recitation rules, each once', () {
      for (final seed in examSegmentSeeds) {
        expect(seed.ruleIds, isNotEmpty, reason: seed.id);
        expect(
          seed.ruleIds.toSet(),
          hasLength(seed.ruleIds.length),
          reason: seed.id,
        );
        for (final ruleId in seed.ruleIds) {
          final rule = _rules[ruleId];
          expect(rule, isNotNull, reason: '${seed.id} $ruleId');
          expect(rule!.isRecitation, isTrue, reason: '${seed.id} $ruleId');
        }
      }
    });

    test('have a positive rule density', () {
      for (final seed in examSegmentSeeds) {
        expect(seed.ruleDensity, isPositive, reason: seed.id);
      }
    });

    test('have a difficulty of 1, 2 or 3 that follows their level', () {
      expect(const ExamSegmentSeed(1, 1, 7, 1, 1, []).difficulty, 1);
      expect(
        const ExamSegmentSeed(
          1,
          1,
          7,
          1,
          1,
          [],
          from: CourseLevel.sanad,
        ).difficulty,
        3,
      );
      for (final seed in examSegmentSeeds) {
        expect(seed.difficulty, inInclusiveRange(1, 3), reason: seed.id);
      }
    });

    test('are given in a level and in every level above it', () {
      for (final seed in examSegmentSeeds) {
        expect(seed.levels.first, seed.from, reason: seed.id);
        expect(seed.levels.last, CourseLevel.sanad, reason: seed.id);
      }
    });

    test('keep a place read in a way of its own out of the courses below '
        'it', () {
      for (final ruleId in levelRaisingRuleIds) {
        expect(_rules[ruleId]!.isRecitation, isTrue, reason: ruleId);
      }
      for (final seed in examSegmentSeeds) {
        for (final ruleId in seed.ruleIds) {
          if (!levelRaisingRuleIds.contains(ruleId)) continue;
          expect(
            _rules[ruleId]!.introducedAt.index,
            lessThanOrEqualTo(seed.from.index),
            reason: '${seed.id} $ruleId',
          );
        }
      }
    });

    test('are kept from a lower course only by such a place', () {
      for (final seed in examSegmentSeeds) {
        if (seed.from == CourseLevel.introductory) continue;
        final raising = seed.ruleIds.where(levelRaisingRuleIds.contains);
        // The question Hamza before the article is read with a long Madd.
        final questionHamza =
            seed.ruleIds.contains('hamzat_wasl_istifham') &&
            seed.ruleIds.contains('madd_lazim');
        expect(raising.isNotEmpty || questionHamza, isTrue, reason: seed.id);
        if (raising.isNotEmpty) {
          final highest = raising
              .map((ruleId) => _rules[ruleId]!.introducedAt.index)
              .reduce(max);
          expect(
            seed.from.index,
            questionHamza ? greaterThanOrEqualTo(highest) : highest,
            reason: seed.id,
          );
        } else {
          expect(seed.from, CourseLevel.advanced, reason: seed.id);
        }
      }
    });

    test(
      'a rule of a higher course read as written keeps the segment open',
      () {
        ExamSegmentSeed segment(String id) =>
            examSegmentSeeds.singleWhere((seed) => seed.id == id);

        // The Alif of «أنا», dropped when reading on.
        final ana = segment('s021_025_029');
        expect(ana.ruleIds, contains('hafs_alifat'));
        expect(ana.from, CourseLevel.introductory);
        expect(ana.levels, CourseLevel.values);

        // The Sad of «بصطة», read as the Mushaf writes it.
        final bastah = segment('s007_068_070');
        expect(bastah.ruleIds, contains('hafs_sad_sin'));
        expect(bastah.from, CourseLevel.introductory);
        expect(bastah.levels, CourseLevel.values);

        for (final ruleId in [
          'hafs_alifat',
          'hafs_sad_sin',
          'hafs_wajhan',
          'ha_kinayah_hafs',
          'ra_wajhan',
        ]) {
          expect(levelRaisingRuleIds, isNot(contains(ruleId)));
          expect(
            examSegmentSeeds.where(
              (seed) =>
                  seed.ruleIds.contains(ruleId) &&
                  seed.from == CourseLevel.introductory,
            ),
            isNotEmpty,
            reason: ruleId,
          );
        }

        // The question Hamza before a verb is only dropped, as written.
        final beforeVerb = segment('s002_079_081');
        expect(beforeVerb.ruleIds, contains('hamzat_wasl_istifham'));
        expect(beforeVerb.from, CourseLevel.introductory);
        // Before the article it is read as a long Alif or eased.
        expect(segment('s010_050_053').from, CourseLevel.advanced);
        expect(segment('s027_057_060').from, CourseLevel.advanced);
      },
    );

    test('hold the places of Sakt that lie inside one surah', () {
      final linked = {for (final seed in examSegmentSeeds) ...seed.ruleIds};
      expect(
        linked,
        containsAll([
          'sakt_iwaja',
          'sakt_marqadina',
          'sakt_man_raq',
          'sakt_bal_ran',
          'sakt_maliyah_halak',
        ]),
      );
      // It lies between two surahs, and a segment stays inside one.
      expect(linked, isNot(contains('sakt_anfal_tawbah')));
    });

    test('place the Sakt of Hafs at its ayah', () {
      ExamSegmentSeed holding(String ruleId) =>
          examSegmentSeeds.singleWhere((seed) => seed.ruleIds.contains(ruleId));
      bool holds(ExamSegmentSeed seed, int surah, int ayah) =>
          seed.surah == surah && seed.ayahFrom <= ayah && ayah <= seed.ayahTo;

      final iwaja = holding('sakt_iwaja');
      expect(holds(iwaja, 18, 1) && holds(iwaja, 18, 2), isTrue);
      expect(holds(holding('sakt_marqadina'), 36, 52), isTrue);
      expect(holds(holding('sakt_man_raq'), 75, 27), isTrue);
      expect(holds(holding('sakt_bal_ran'), 83, 14), isTrue);
      final maliyah = holding('sakt_maliyah_halak');
      expect(holds(maliyah, 69, 28) && holds(maliyah, 69, 29), isTrue);
    });

    test('are read by the ExamSegment entity', () {
      final segments = _segments();
      expect(segments, hasLength(examSegmentSeeds.length));
      for (final (index, segment) in segments.indexed) {
        final seed = examSegmentSeeds[index];
        expect(segment.id, seed.id);
        expect(segment.ruleIds, seed.ruleIds);
        expect(segment.ruleDensity, seed.ruleDensity);
        expect(segment.difficulty, seed.difficulty);
        expect(segment.isActive, isTrue);
      }
    });
  });

  group('segment selection over the seed', () {
    final segments = _segments();

    test('every course has many eligible segments, more at each level', () {
      final counts = <int>[];
      for (final level in CourseLevel.values) {
        final weights = _weightsOf(level);
        final eligible = segments.where(
          (segment) =>
              segment.courseIds.contains(level.value) &&
              SegmentSelector.weightOf(segment, weights) > 0,
        );
        counts.add(eligible.length);
      }
      expect(counts.first, greaterThan(150));
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
      }
      expect(counts[1], greaterThan(counts[0]));
      expect(counts[2], greaterThan(counts[1]));
      expect(counts.last, segments.length);
    });

    test('selects a segment of the course for every course', () {
      const selector = SegmentSelector();
      for (final level in CourseLevel.values) {
        final random = Random(level.index);
        final selected = <String>{};
        for (var i = 0; i < 200; i++) {
          final segment = selector.select(
            courseId: level.value,
            segments: segments,
            courseRuleWeights: _weightsOf(level),
            random: random,
          )!;
          expect(segment.courseIds, contains(level.value));
          selected.add(segment.id);
        }
        // The choice is spread over the segments, not stuck on a few.
        expect(selected.length, greaterThan(50), reason: level.value);
      }
    });
  });

  group('CurriculumSeeder segments', () {
    late _MemorySeedStore store;

    setUp(() => store = _MemorySeedStore());

    test('writes the segments with the fields of the collection', () async {
      final result = await CurriculumSeeder(store).seed();

      expect(result.segmentsCreated, examSegmentSeeds.length);
      expect(result.segmentsUpdated, 0);
      final segments = store.docs(FirebaseCollections.examSegments);
      expect(segments, hasLength(examSegmentSeeds.length));
      expect(segments['s018_001_004'], {
        'surah': 18,
        'ayahFrom': 1,
        'ayahTo': 4,
        'page': 293,
        'ruleIds': contains('sakt_iwaja'),
        'courseIds': ['qualifying', 'advanced', 'sanad'],
        'difficulty': 2,
        'ruleDensity': isPositive,
        'isActive': true,
        'createdAt': 'now',
      });
    });

    test('links the segments to stored courses and rules', () async {
      await CurriculumSeeder(store).seed();

      final courses = store.docs(FirebaseCollections.courses);
      final rules = store.docs(FirebaseCollections.tajweedRules);
      for (final segment
          in store.docs(FirebaseCollections.examSegments).values) {
        for (final courseId in segment['courseIds'] as List) {
          expect(courses, contains(courseId));
        }
        for (final ruleId in segment['ruleIds'] as List) {
          expect(rules, contains(ruleId));
        }
      }
    });

    test('uses the IDs of a course and a rule that already exist', () async {
      store.docs(FirebaseCollections.courses)['course-1'] = {
        'name': 'الدورة التمهيدية',
        'level': 'introductory',
        'isActive': true,
      };
      store.docs(FirebaseCollections.tajweedRules)['old-rule'] = {
        'name': 'المد الطبيعي',
      };

      await CurriculumSeeder(store).seed();

      final first = store.docs(
        FirebaseCollections.examSegments,
      )[examSegmentSeeds.first.id]!;
      expect(first['courseIds'], contains('course-1'));
      expect(first['courseIds'], isNot(contains('introductory')));
      expect(first['ruleIds'], contains('old-rule'));
      expect(first['ruleIds'], isNot(contains('madd_tabii')));
    });

    test('writes nothing when run again', () async {
      await CurriculumSeeder(store).seed();

      final result = await CurriculumSeeder(store).seed();

      expect(result.segmentsCreated, 0);
      expect(result.segmentsUpdated, 0);
      expect(result.wroteNothing, isTrue);
    });

    test(
      'keeps an isActive changed by hand and restores the definition',
      () async {
        await CurriculumSeeder(store).seed();
        final id = examSegmentSeeds.first.id;
        store.docs(FirebaseCollections.examSegments)[id]!
          ..['isActive'] = false
          ..['ruleDensity'] = 99
          ..['ruleIds'] = ['madd_tabii'];

        final result = await CurriculumSeeder(store).seed();

        expect(result.segmentsCreated, 0);
        expect(result.segmentsUpdated, 1);
        final segment = store.docs(FirebaseCollections.examSegments)[id]!;
        expect(segment['isActive'], isFalse);
        expect(segment['ruleDensity'], examSegmentSeeds.first.ruleDensity);
        expect(segment['ruleIds'], examSegmentSeeds.first.ruleIds);
      },
    );
  });
}
