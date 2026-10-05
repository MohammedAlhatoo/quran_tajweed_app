import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/firebase_collections.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seed.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/questions/data/seed/question_bank_seed.dart';
import 'package:quran_tajweed_app/features/questions/data/seed/question_seed.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/question.dart';
import 'package:quran_tajweed_app/features/questions/domain/services/question_selector.dart';

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

final _rules = {for (final rule in tajweedRuleSeeds) rule.id: rule};

/// The `question_bank` documents of the course of [level], as the app reads
/// them.
List<Question> _questionsOf(CourseLevel level) => [
  for (final seed in questionsOfLevel(level))
    Question.fromMap('${level.value}_${seed.key}', {
      ...seed.toMap(
        courseId: level.value,
        ruleId: seed.ruleId,
        difficulty: questionDifficulty(seed),
        level: questionLevel(seed),
      ),
      'isActive': true,
    })!,
];

void main() {
  group('QuestionType', () {
    test('reads its stored value', () {
      expect(
        QuestionType.fromValue('multiple_choice'),
        QuestionType.multipleChoice,
      );
      expect(QuestionType.fromValue('true_false'), QuestionType.trueFalse);
      expect(QuestionType.fromValue('essay'), isNull);
      expect(QuestionType.fromValue(null), isNull);
    });
  });

  group('Question.fromMap', () {
    test('reads the difficulty', () {
      final question = Question.fromMap('q1', {
        'courseId': 'c1',
        'ruleId': 'madd_tabii',
        'type': 'multiple_choice',
        'question': 'سؤال',
        'options': ['أ', 'ب'],
        'difficulty': 3,
        'level': 'advanced',
        'isActive': true,
      })!;

      expect(question.level, CourseLevel.advanced);
      expect(question.difficulty, 3);
    });

    test('a document without a difficulty is read as easy', () {
      final question = Question.fromMap('q1', {
        'courseId': 'c1',
        'type': 'multiple_choice',
        'question': 'سؤال',
      })!;

      expect(question.difficulty, 1);
    });
  });

  group('question seeds', () {
    test('refer to an existing rule', () {
      for (final seed in questionSeeds) {
        expect(_rules, contains(seed.ruleId), reason: seed.question);
      }
    });

    test('give every rule a question', () {
      expect({
        for (final seed in questionSeeds) seed.ruleId,
      }, _rules.keys.toSet());
    });

    test('have no duplicate keys or texts', () {
      final keys = [for (final seed in questionSeeds) seed.key];
      final texts = [for (final seed in questionSeeds) seed.question];
      expect(keys.toSet(), hasLength(keys.length));
      expect(texts.toSet(), hasLength(texts.length));
    });

    test('have a text and at least two distinct options', () {
      for (final seed in questionSeeds) {
        expect(seed.question.trim(), isNotEmpty);
        expect(seed.options.length, greaterThanOrEqualTo(2), reason: seed.key);
        expect(
          seed.options.toSet(),
          hasLength(seed.options.length),
          reason: seed.key,
        );
        for (final option in seed.options) {
          expect(option.trim(), isNotEmpty, reason: seed.key);
        }
      }
    });

    test('hold the correct answer among the options, word for word', () {
      for (final seed in questionSeeds) {
        expect(
          seed.options.where((option) => option == seed.correctAnswer),
          hasLength(1),
          reason: seed.key,
        );
      }
    });

    test('a true or false question offers exactly the two answers', () {
      final trueFalse = questionSeeds.where(
        (seed) => seed.type == QuestionType.trueFalse,
      );
      expect(trueFalse, isNotEmpty);
      for (final seed in trueFalse) {
        expect(seed.options, ['صح', 'خطأ'], reason: seed.key);
      }
    });

    test('do not keep the correct answer in one place', () {
      final places = {
        for (final seed in questionSeeds)
          if (seed.type == QuestionType.multipleChoice)
            seed.options.indexOf(seed.correctAnswer),
      };
      expect(places, containsAll([0, 1, 2, 3]));
    });

    test('show the options in the same order every time', () {
      for (final seed in questionSeeds) {
        expect(seed.options, seed.options);
      }
    });

    test('have a difficulty from 1 to 3 that follows the level', () {
      for (final seed in questionSeeds) {
        expect(questionDifficulty(seed), inInclusiveRange(1, 3));
      }
      final byRule = {for (final seed in questionSeeds) seed.ruleId: seed};
      expect(questionDifficulty(byRule['madd_tabii']!), 1);
      expect(questionDifficulty(byRule['madd_muttasil']!), 2);
      expect(questionDifficulty(byRule['madd_tamkin']!), 3);
      expect(questionDifficulty(byRule['hafs_wajhan']!), 3);
    });

    test('never put the correct answer in the question document', () {
      for (final seed in questionSeeds) {
        final document = seed.toMap(
          courseId: 'c1',
          ruleId: seed.ruleId,
          difficulty: 1,
          level: CourseLevel.introductory,
        );
        expect(document.keys, [
          'courseId',
          'ruleId',
          'level',
          'type',
          'question',
          'options',
          'difficulty',
        ]);
        expect(seed.answerToMap(), {'correctAnswer': seed.correctAnswer});
      }
    });
  });

  group('course questions', () {
    test('ask only about the rules the course covers', () {
      for (final level in CourseLevel.values) {
        final covered = {for (final rule in rulesOfLevel(level)) rule.id};
        for (final seed in questionsOfLevel(level)) {
          expect(covered, contains(seed.ruleId));
        }
      }
    });

    test('grow with the level, and the sanad course asks them all', () {
      final counts = [
        for (final level in CourseLevel.values) questionsOfLevel(level).length,
      ];
      expect(counts.first, greaterThanOrEqualTo(10));
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThan(counts[i - 1]));
      }
      expect(counts.last, questionSeeds.length);
    });

    test('are enough to start an examination in every course', () {
      for (final level in CourseLevel.values) {
        final selected = const QuestionSelector().select(
          courseId: level.value,
          courseLevel: level,
          questions: _questionsOf(level),
          courseRuleWeights: const {},
          random: Random(1),
        );

        expect(selected, hasLength(10), reason: level.value);
        expect({for (final question in selected!) question.id}, hasLength(10));
      }
    });

    test('belong to the level that introduces their rule', () {
      for (final seed in questionSeeds) {
        expect(questionLevel(seed), _rules[seed.ruleId]!.introducedAt);
      }
    });

    test('fill the share of every level in every examination', () {
      for (final level in CourseLevel.values) {
        final questions = _questionsOf(level);
        final weights = {
          for (final rule in rulesOfLevel(level))
            rule.id: courseRuleWeight(rule, level).toDouble(),
        };
        for (var seed = 0; seed < 100; seed++) {
          final selected = const QuestionSelector().select(
            courseId: level.value,
            courseLevel: level,
            questions: questions,
            courseRuleWeights: weights,
            random: Random(seed),
          )!;

          final counts = <CourseLevel, int>{};
          for (final question in selected) {
            counts[question.level] = (counts[question.level] ?? 0) + 1;
          }
          expect(
            counts,
            QuestionSelector.quotasOf(level),
            reason: '${level.value} seed $seed',
          );
        }
      }
    });
  });

  group('CurriculumSeeder questions', () {
    late _MemorySeedStore store;

    setUp(() => store = _MemorySeedStore());

    int expectedCount() =>
        [for (final level in CourseLevel.values) questionsOfLevel(level).length]
            .reduce((a, b) => a + b);

    test('writes each question once for every course that covers it', () async {
      final result = await CurriculumSeeder(store).seed();

      final bank = store.docs(FirebaseCollections.questionBank);
      expect(result.questionsCreated, expectedCount());
      expect(result.questionsUpdated, 0);
      expect(bank, hasLength(expectedCount()));
      expect(bank['introductory_madd_tabii_1'], {
        'courseId': 'introductory',
        'ruleId': 'madd_tabii',
        'level': 'introductory',
        'type': 'multiple_choice',
        'question': 'ما مقدار المد الطبيعي؟',
        'options': hasLength(4),
        'difficulty': 1,
        'isActive': true,
        'createdAt': 'now',
        'updatedAt': 'now',
      });
      for (final level in CourseLevel.values) {
        expect(bank, contains('${level.value}_madd_tabii_1'));
      }
      expect(bank, isNot(contains('introductory_madd_muttasil_1')));
      expect(bank, contains('qualifying_madd_muttasil_1'));
    });

    test('links every question to an existing course and rule', () async {
      await CurriculumSeeder(store).seed();

      final courses = store.docs(FirebaseCollections.courses);
      final rules = store.docs(FirebaseCollections.tajweedRules);
      final links = {
        for (final link in store.docs(FirebaseCollections.courseRules).values)
          '${link['courseId']}|${link['ruleId']}',
      };
      for (final question
          in store.docs(FirebaseCollections.questionBank).values) {
        expect(courses, contains(question['courseId']));
        expect(rules, contains(question['ruleId']));
        expect(
          links,
          contains('${question['courseId']}|${question['ruleId']}'),
        );
      }
    });

    test(
      'keeps the answers in question_answers only, under the same IDs',
      () async {
        final result = await CurriculumSeeder(store).seed();

        final bank = store.docs(FirebaseCollections.questionBank);
        final answers = store.docs(FirebaseCollections.questionAnswers);
        expect(result.answersWritten, expectedCount());
        expect(answers.keys.toSet(), bank.keys.toSet());
        for (final entry in bank.entries) {
          expect(entry.value, isNot(contains('correctAnswer')));
          final answer = answers[entry.key]!;
          expect(answer.keys, ['correctAnswer']);
          expect(entry.value['options'], contains(answer['correctAnswer']));
        }
        expect(answers['introductory_madd_tabii_1'], {
          'correctAnswer': 'حركتان',
        });
      },
    );

    test('writes nothing when run again', () async {
      await CurriculumSeeder(store).seed();

      final result = await CurriculumSeeder(store).seed();

      expect(result.wroteNothing, isTrue);
      expect(
        store.docs(FirebaseCollections.questionBank),
        hasLength(expectedCount()),
      );
    });

    test('writes the level that introduces the rule, whatever the course, and '
        'adds it to a question stored without it', () async {
      await CurriculumSeeder(store).seed();

      final bank = store.docs(FirebaseCollections.questionBank);
      for (final seed in questionSeeds) {
        final introducedAt = _rules[seed.ruleId]!.introducedAt;
        for (final course in CourseLevel.values) {
          if (course.index < introducedAt.index) continue;
          expect(
            bank['${course.value}_${seed.key}'],
            containsPair('level', introducedAt.value),
          );
        }
      }

      for (final document in bank.values) {
        document.remove('level');
      }
      bank['sanad_madd_tabii_1']!['isActive'] = false;

      final result = await CurriculumSeeder(store).seed();

      expect(result.questionsCreated, 0);
      expect(result.questionsUpdated, expectedCount());
      expect(bank['sanad_madd_tabii_1'], containsPair('level', 'introductory'));
      expect(bank['sanad_madd_tabii_1'], containsPair('isActive', false));
      expect(
        bank['sanad_madd_muttasil_1'],
        containsPair('level', 'qualifying'),
      );
    });

    test('uses the ID of an existing course and of a reused rule', () async {
      store.docs(FirebaseCollections.courses)['course-1'] = {
        'name': 'الدورة التمهيدية',
        'level': 'introductory',
        'isActive': true,
      };
      store.docs(FirebaseCollections.tajweedRules)['old-rule'] = {
        'name': 'المد الطبيعي',
      };

      await CurriculumSeeder(store).seed();

      final bank = store.docs(FirebaseCollections.questionBank);
      expect(bank, isNot(contains('introductory_madd_tabii_1')));
      expect(
        bank['course-1_madd_tabii_1'],
        containsPair('courseId', 'course-1'),
      );
      expect(bank['course-1_madd_tabii_1'], containsPair('ruleId', 'old-rule'));
    });

    test('keeps an isActive changed by hand and restores the text', () async {
      await CurriculumSeeder(store).seed();
      store.docs(FirebaseCollections.questionBank)['introductory_madd_tabii_1']!
        ..['isActive'] = false
        ..['question'] = 'قديم';

      final result = await CurriculumSeeder(store).seed();

      expect(result.questionsCreated, 0);
      expect(result.questionsUpdated, 1);
      expect(result.answersWritten, 0);
      final question = store.docs(
        FirebaseCollections.questionBank,
      )['introductory_madd_tabii_1']!;
      expect(question['isActive'], isFalse);
      expect(question['question'], 'ما مقدار المد الطبيعي؟');
    });

    test('corrects a stored answer that differs from the seed', () async {
      await CurriculumSeeder(store).seed();
      store.docs(
        FirebaseCollections.questionAnswers,
      )['introductory_madd_tabii_1']!['correctAnswer'] = 'ست حركات';

      final result = await CurriculumSeeder(store).seed();

      expect(result.answersWritten, 1);
      expect(result.questionsUpdated, 0);
      expect(
        store.docs(
          FirebaseCollections.questionAnswers,
        )['introductory_madd_tabii_1'],
        {'correctAnswer': 'حركتان'},
      );
    });
  });
}
