import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/segment_selector.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/question.dart';
import 'package:quran_tajweed_app/features/questions/domain/services/question_selector.dart';

ExamSegment _segment(
  String id, {
  List<String> ruleIds = const ['rule-a'],
  List<String> courseIds = const ['course-1'],
  double ruleDensity = 1,
  bool isActive = true,
}) {
  return ExamSegment(
    id: id,
    surah: 2,
    ayahFrom: 1,
    ayahTo: 5,
    page: 2,
    ruleIds: ruleIds,
    courseIds: courseIds,
    ruleDensity: ruleDensity,
    isActive: isActive,
  );
}

Question _question(
  String id, {
  String ruleId = 'rule-a',
  String courseId = 'course-1',
  bool isActive = true,
  CourseLevel level = CourseLevel.introductory,
}) {
  return Question(
    id: id,
    courseId: courseId,
    ruleId: ruleId,
    type: 'multiple_choice',
    question: 'سؤال $id',
    options: const ['أ', 'ب'],
    isActive: isActive,
    level: level,
  );
}

/// [perLevel] questions of the content of each level, each on its own rule.
List<Question> _bank(int perLevel, {List<CourseLevel>? levels}) => [
  for (final level in levels ?? CourseLevel.values)
    for (var i = 0; i < perLevel; i++)
      _question(
        '${level.value}-$i',
        ruleId: '${level.value}-rule-$i',
        level: level,
      ),
];

Map<CourseLevel, int> _countByLevel(List<Question> questions) {
  final counts = <CourseLevel, int>{};
  for (final question in questions) {
    counts[question.level] = (counts[question.level] ?? 0) + 1;
  }
  return counts;
}

void main() {
  group('SegmentSelector', () {
    const selector = SegmentSelector();
    const weights = {'rule-a': 2.0, 'rule-b': 1.0};

    test('weight is density times the weights of the course rules', () {
      final segment = _segment(
        's1',
        ruleIds: ['rule-a', 'rule-b', 'rule-other', 'rule-a'],
        ruleDensity: 0.5,
      );

      expect(SegmentSelector.weightOf(segment, weights), 1.5);
    });

    test('skips inactive, other-course and zero-weight segments', () {
      final segments = [
        _segment('inactive', isActive: false),
        _segment('other-course', courseIds: ['course-2']),
        _segment('no-course-rule', ruleIds: ['rule-other']),
        _segment('zero-density', ruleDensity: 0),
        _segment('valid'),
      ];

      for (var seed = 0; seed < 50; seed++) {
        final selected = selector.select(
          courseId: 'course-1',
          segments: segments,
          courseRuleWeights: weights,
          random: Random(seed),
        );
        expect(selected!.id, 'valid');
      }
    });

    test('returns null when no segment qualifies', () {
      final selected = selector.select(
        courseId: 'course-1',
        segments: [
          _segment('s1', ruleIds: ['rule-other']),
        ],
        courseRuleWeights: weights,
        random: Random(1),
      );

      expect(selected, isNull);
    });

    test('picks heavier segments more often', () {
      final segments = [
        _segment('light', ruleDensity: 1),
        _segment('heavy', ruleDensity: 9),
      ];
      final random = Random(7);
      var heavy = 0;
      const runs = 2000;

      for (var i = 0; i < runs; i++) {
        final selected = selector.select(
          courseId: 'course-1',
          segments: segments,
          courseRuleWeights: weights,
          random: random,
        );
        if (selected!.id == 'heavy') heavy++;
      }

      // Expected share is 90%.
      expect(heavy / runs, closeTo(0.9, 0.03));
    });
  });

  group('QuestionSelector', () {
    const selector = QuestionSelector();

    test('returns ten distinct active questions of the course', () {
      final questions = [
        for (var i = 0; i < 15; i++) _question('q$i', ruleId: 'rule-${i % 3}'),
        _question('inactive', isActive: false),
        _question('other-course', courseId: 'course-2'),
      ];

      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.introductory,
        questions: questions,
        courseRuleWeights: const {},
        random: Random(3),
      )!;

      expect(selected, hasLength(10));
      expect(selected.map((q) => q.id).toSet(), hasLength(10));
      expect(selected.every((q) => q.isActive), isTrue);
      expect(selected.every((q) => q.courseId == 'course-1'), isTrue);
    });

    test('spreads the questions across the rules', () {
      final questions = [
        for (var i = 0; i < 20; i++) _question('a$i', ruleId: 'rule-a'),
        for (var i = 0; i < 20; i++) _question('b$i', ruleId: 'rule-b'),
      ];

      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.introductory,
        questions: questions,
        courseRuleWeights: const {'rule-a': 5, 'rule-b': 1},
        random: Random(11),
      )!;

      expect(selected.where((q) => q.ruleId == 'rule-a'), hasLength(5));
      expect(selected.where((q) => q.ruleId == 'rule-b'), hasLength(5));
    });

    test('uses the remaining rules when one runs out of questions', () {
      final questions = [
        _question('a0', ruleId: 'rule-a'),
        for (var i = 0; i < 12; i++) _question('b$i', ruleId: 'rule-b'),
      ];

      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.introductory,
        questions: questions,
        courseRuleWeights: const {},
        random: Random(5),
      )!;

      expect(selected, hasLength(10));
      expect(selected.where((q) => q.ruleId == 'rule-a'), hasLength(1));
    });

    test('returns null when fewer than ten questions are available', () {
      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.introductory,
        questions: [for (var i = 0; i < 9; i++) _question('q$i')],
        courseRuleWeights: const {},
        random: Random(1),
      );

      expect(selected, isNull);
    });

    test('the shares of every course add up to ten, its own level first', () {
      for (final level in CourseLevel.values) {
        final quotas = QuestionSelector.quotasOf(level);
        expect(quotas.values.reduce((a, b) => a + b), 10, reason: level.value);
        expect(quotas.keys.every((l) => l.index <= level.index), isTrue);
        for (final lower in quotas.keys.where((l) => l != level)) {
          expect(quotas[level], greaterThan(quotas[lower]!));
        }
      }
      expect(
        QuestionSelector.quotasOf(CourseLevel.sanad, count: 5).values,
        everyElement(greaterThanOrEqualTo(0)),
      );
      expect(
        QuestionSelector.quotasOf(
          CourseLevel.sanad,
          count: 5,
        ).values.reduce((a, b) => a + b),
        5,
      );
    });

    test('shares the questions between the levels exactly, whatever the '
        'random order', () {
      final questions = _bank(20);
      for (final level in CourseLevel.values) {
        for (var seed = 0; seed < 200; seed++) {
          final selected = selector.select(
            courseId: 'course-1',
            courseLevel: level,
            questions: questions
                .where((q) => q.level.index <= level.index)
                .toList(),
            courseRuleWeights: const {},
            random: Random(seed),
          )!;

          expect(selected.map((q) => q.id).toSet(), hasLength(10));
          expect(
            _countByLevel(selected),
            QuestionSelector.quotasOf(level),
            reason: '${level.value} seed $seed',
          );
        }
      }
    });

    test('does not group the questions by level', () {
      final orders = <String>{};
      for (var seed = 0; seed < 20; seed++) {
        final selected = selector.select(
          courseId: 'course-1',
          courseLevel: CourseLevel.sanad,
          questions: _bank(20),
          courseRuleWeights: const {},
          random: Random(seed),
        )!;
        orders.add(selected.map((q) => q.level.index).join());
      }

      expect(orders.length, greaterThan(10));
    });

    test('takes the shortfall of a level from the nearest lower level', () {
      final questions = [
        ..._bank(2, levels: [CourseLevel.sanad]),
        ..._bank(20, levels: CourseLevel.values.sublist(0, 3)),
      ];

      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.sanad,
        questions: questions,
        courseRuleWeights: const {},
        random: Random(4),
      )!;

      expect(_countByLevel(selected), {
        CourseLevel.sanad: 2,
        CourseLevel.advanced: 6,
        CourseLevel.qualifying: 1,
        CourseLevel.introductory: 1,
      });
    });

    test('takes the shortfall from the higher levels when the lower ones '
        'run out', () {
      final questions = [
        ..._bank(20, levels: [CourseLevel.advanced]),
        ..._bank(2, levels: [CourseLevel.qualifying]),
      ];

      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.advanced,
        questions: questions,
        courseRuleWeights: const {},
        random: Random(4),
      )!;

      expect(_countByLevel(selected), {
        CourseLevel.advanced: 8,
        CourseLevel.qualifying: 2,
      });
    });

    test('still fills an examination from questions without a level', () {
      final selected = selector.select(
        courseId: 'course-1',
        courseLevel: CourseLevel.sanad,
        questions: [
          for (var i = 0; i < 30; i++) _question('q$i', ruleId: 'rule-$i'),
        ],
        courseRuleWeights: const {},
        random: Random(2),
      )!;

      expect(selected.map((q) => q.id).toSet(), hasLength(10));
    });
  });
}
