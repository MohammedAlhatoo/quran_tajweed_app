import 'package:flutter/foundation.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../exams/data/seed/exam_segments_seed.dart';
import '../../../questions/data/seed/question_bank_seed.dart';
import '../../domain/entities/course_level.dart';
import 'curriculum_seed.dart';

/// Where [CurriculumSeeder] reads and writes documents.
abstract interface class SeedStore {
  /// The value written to `createdAt` and `updatedAt`.
  Object get timestamp;

  /// Every document of [collection], keyed by its ID.
  Future<Map<String, Map<String, dynamic>>> readAll(String collection);

  /// Writes [documents], keyed by their IDs, into [collection]. The fields
  /// of an existing document that are not given are kept.
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  );
}

/// What one run of [CurriculumSeeder.seed] wrote.
class CurriculumSeedResult {
  const CurriculumSeedResult({
    required this.coursesCreated,
    required this.rulesCreated,
    required this.rulesUpdated,
    required this.courseRulesCreated,
    required this.questionsCreated,
    required this.questionsUpdated,
    required this.answersWritten,
    required this.segmentsCreated,
    required this.segmentsUpdated,
  });

  final int coursesCreated;
  final int rulesCreated;
  final int rulesUpdated;
  final int courseRulesCreated;
  final int questionsCreated;
  final int questionsUpdated;

  /// The `question_answers` documents created or corrected.
  final int answersWritten;

  final int segmentsCreated;
  final int segmentsUpdated;

  bool get wroteNothing =>
      coursesCreated +
          rulesCreated +
          rulesUpdated +
          courseRulesCreated +
          questionsCreated +
          questionsUpdated +
          answersWritten +
          segmentsCreated +
          segmentsUpdated ==
      0;
}

/// Writes the four courses, the Tajweed rules, their links, the question
/// bank with its answers, and the examination segments.
///
/// It can be run again safely: it adds what is missing and never creates a
/// second copy of a course, a rule, a link, a question or a segment. The data
/// belongs to no user.
class CurriculumSeeder {
  const CurriculumSeeder(this._store);

  final SeedStore _store;

  Future<CurriculumSeedResult> seed() async {
    final courses = await _seedCourses();
    final rules = await _seedRules();
    final links = await _seedCourseRules(courses.ids, rules.ids);
    final questions = await _seedQuestions(courses.ids, rules.ids);
    final segments = await _seedSegments(courses.ids, rules.ids);
    return CurriculumSeedResult(
      coursesCreated: courses.created,
      rulesCreated: rules.created,
      rulesUpdated: rules.updated,
      courseRulesCreated: links,
      questionsCreated: questions.created,
      questionsUpdated: questions.updated,
      answersWritten: questions.answers,
      segmentsCreated: segments.created,
      segmentsUpdated: segments.updated,
    );
  }

  /// An existing course of a level is kept as it is, under its own ID.
  Future<({Map<CourseLevel, String> ids, int created})> _seedCourses() async {
    final existing = await _store.readAll(FirebaseCollections.courses);
    final ids = <CourseLevel, String>{};
    final writes = <String, Map<String, Object?>>{};
    for (final seed in courseSeeds) {
      final existingId = existing.entries
          .where((entry) => entry.value['level'] == seed.level.value)
          .firstOrNull
          ?.key;
      ids[seed.level] = existingId ?? seed.id;
      if (existingId == null) {
        writes[seed.id] = {
          ...seed.toMap(),
          'createdAt': _store.timestamp,
          'updatedAt': _store.timestamp,
        };
      }
    }
    await _store.writeAll(FirebaseCollections.courses, writes);
    return (ids: ids, created: writes.length);
  }

  /// An existing rule keeps its ID and its `isActive`; its definition is
  /// brought up to date. A rule stored under another ID with the same name is
  /// reused instead of being written twice.
  Future<({Map<String, String> ids, int created, int updated})>
  _seedRules() async {
    final existing = await _store.readAll(FirebaseCollections.tajweedRules);
    final idsByName = {
      for (final entry in existing.entries)
        if (entry.value['name'] case final String name) name: entry.key,
    };
    final ids = <String, String>{};
    final writes = <String, Map<String, Object?>>{};
    var created = 0;
    for (final seed in tajweedRuleSeeds) {
      final stored = existing[seed.id];
      if (stored == null) {
        final sameNameId = idsByName[seed.name];
        ids[seed.id] = sameNameId ?? seed.id;
        if (sameNameId == null) {
          created++;
          writes[seed.id] = {
            ...seed.toMap(),
            'createdAt': _store.timestamp,
            'updatedAt': _store.timestamp,
          };
        }
        continue;
      }
      ids[seed.id] = seed.id;
      final definition = seed.toMap()..remove('isActive');
      final changed = definition.entries.any(
        (field) => stored[field.key] != field.value,
      );
      if (changed) {
        writes[seed.id] = {...definition, 'updatedAt': _store.timestamp};
      }
    }
    await _store.writeAll(FirebaseCollections.tajweedRules, writes);
    return (ids: ids, created: created, updated: writes.length - created);
  }

  /// An existing link is left untouched, so a weight adjusted by hand
  /// survives a new run.
  Future<int> _seedCourseRules(
    Map<CourseLevel, String> courseIds,
    Map<String, String> ruleIds,
  ) async {
    final existing = await _store.readAll(FirebaseCollections.courseRules);
    final linked = {
      for (final data in existing.values)
        '${data['courseId']}|${data['ruleId']}',
    };
    final writes = <String, Map<String, Object?>>{};
    for (final seed in courseRuleSeeds) {
      final courseId = courseIds[seed.level]!;
      final ruleId = ruleIds[seed.ruleId]!;
      if (!linked.add('$courseId|$ruleId')) continue;
      writes['${courseId}_$ruleId'] = {
        'courseId': courseId,
        'ruleId': ruleId,
        'weight': seed.weight,
        'createdAt': _store.timestamp,
      };
    }
    await _store.writeAll(FirebaseCollections.courseRules, writes);
    return writes.length;
  }

  /// A question is written once for every course that covers its rule, under
  /// `{courseId}_{key}`, and its correct answer under the same ID in
  /// `question_answers` only. An existing question keeps its `isActive`; its
  /// definition and its answer are brought up to date.
  Future<({int created, int updated, int answers})> _seedQuestions(
    Map<CourseLevel, String> courseIds,
    Map<String, String> ruleIds,
  ) async {
    final existing = await _store.readAll(FirebaseCollections.questionBank);
    final existingAnswers = await _store.readAll(
      FirebaseCollections.questionAnswers,
    );
    final questions = <String, Map<String, Object?>>{};
    final answers = <String, Map<String, Object?>>{};
    var created = 0;
    for (final course in courseSeeds) {
      final courseId = courseIds[course.level]!;
      for (final seed in questionsOfLevel(course.level)) {
        final id = '${courseId}_${seed.key}';
        if (existingAnswers[id]?['correctAnswer'] != seed.correctAnswer) {
          answers[id] = seed.answerToMap();
        }
        final definition = seed.toMap(
          courseId: courseId,
          ruleId: ruleIds[seed.ruleId]!,
          difficulty: questionDifficulty(seed),
          level: questionLevel(seed),
        );
        final stored = existing[id];
        if (stored == null) {
          created++;
          questions[id] = {
            ...definition,
            'isActive': true,
            'createdAt': _store.timestamp,
            'updatedAt': _store.timestamp,
          };
          continue;
        }
        final changed = definition.entries.any(
          (field) => !_sameValue(stored[field.key], field.value),
        );
        if (changed) {
          questions[id] = {...definition, 'updatedAt': _store.timestamp};
        }
      }
    }
    // The answers go first, so a question is never selectable without one.
    await _store.writeAll(FirebaseCollections.questionAnswers, answers);
    await _store.writeAll(FirebaseCollections.questionBank, questions);
    return (
      created: created,
      updated: questions.length - created,
      answers: answers.length,
    );
  }

  /// A segment is written under the ID of its reference, linked to the courses
  /// it is given in and to the rules that have a place in it. An existing
  /// segment keeps its `isActive`; its definition is brought up to date.
  Future<({int created, int updated})> _seedSegments(
    Map<CourseLevel, String> courseIds,
    Map<String, String> ruleIds,
  ) async {
    final existing = await _store.readAll(FirebaseCollections.examSegments);
    final writes = <String, Map<String, Object?>>{};
    var created = 0;
    for (final seed in examSegmentSeeds) {
      final definition = seed.toMap(
        ruleIds: [for (final ruleId in seed.ruleIds) ruleIds[ruleId]!],
        courseIds: [for (final level in seed.levels) courseIds[level]!],
      );
      final stored = existing[seed.id];
      if (stored == null) {
        created++;
        writes[seed.id] = {
          ...definition,
          'isActive': true,
          'createdAt': _store.timestamp,
        };
        continue;
      }
      final changed = definition.entries.any(
        (field) => !_sameValue(stored[field.key], field.value),
      );
      if (changed) writes[seed.id] = definition;
    }
    await _store.writeAll(FirebaseCollections.examSegments, writes);
    return (created: created, updated: writes.length - created);
  }

  /// Lists are compared by their items: a list read from the store is never
  /// the list of the seed itself.
  static bool _sameValue(Object? stored, Object? seed) =>
      stored is List && seed is List
      ? listEquals(stored, seed)
      : stored == seed;
}
