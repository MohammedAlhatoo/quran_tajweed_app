import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/firebase_collections.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seed.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';
import 'package:quran_tajweed_app/features/exams/data/seed/exam_segments_seed.dart';

import '../../tool/src/seed_plan.dart';

class _MemorySeedStore implements SeedStore {
  final Map<String, Map<String, Map<String, dynamic>>> collections = {};
  int writeCalls = 0;

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
    writeCalls++;
    for (final entry in documents.entries) {
      docs(collection).putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }
}

Future<Map<String, CollectionPlan>> _run(
  _MemorySeedStore inner, {
  required bool apply,
}) async {
  final store = RecordingSeedStore(inner, apply: apply);
  final result = await CurriculumSeeder(store).seed();
  return {
    for (final plan in buildSeedPlan(store, result)) plan.collection: plan,
  };
}

void main() {
  late _MemorySeedStore inner;

  setUp(() => inner = _MemorySeedStore());

  test('a dry run writes nothing and counts every document', () async {
    final plans = await _run(inner, apply: false);

    expect(inner.writeCalls, 0);
    expect(inner.collections.values.every((docs) => docs.isEmpty), isTrue);
    expect(plans.keys, seedCollections);
    expect(plans[FirebaseCollections.courses]!.created, hasLength(4));
    expect(
      plans[FirebaseCollections.tajweedRules]!.created,
      hasLength(tajweedRuleSeeds.length),
    );
    expect(
      plans[FirebaseCollections.courseRules]!.created,
      hasLength(courseRuleSeeds.length),
    );
    expect(
      plans[FirebaseCollections.questionAnswers]!.created,
      plans[FirebaseCollections.questionBank]!.created,
    );
    expect(
      plans[FirebaseCollections.examSegments]!.created,
      hasLength(examSegmentSeeds.length),
    );
    for (final plan in plans.values) {
      expect(plan.updated, isEmpty);
      expect(plan.orphaned, isEmpty);
    }
  });

  test('a dry run plans what an apply writes', () async {
    final planned = await _run(inner, apply: false);
    final applied = await _run(inner, apply: true);

    for (final collection in seedCollections) {
      expect(applied[collection]!.created, planned[collection]!.created);
      expect(
        inner.docs(collection).keys.toList()..sort(),
        planned[collection]!.created,
      );
    }

    final again = await _run(inner, apply: true);
    for (final plan in again.values) {
      expect(plan.created, isEmpty);
      expect(plan.updated, isEmpty);
      expect(plan.orphaned, isEmpty);
    }
  });

  test('reports the existing courses that need an update', () async {
    inner.docs(FirebaseCollections.courses)['course-1'] = {
      'name': 'تمهيدية',
      'description': 'وصف قديم',
      'level': 'introductory',
      'isActive': false,
    };

    final plans = await _run(inner, apply: false);

    final courses = plans[FirebaseCollections.courses]!;
    expect(courses.created, ['advanced', 'qualifying', 'sanad']);
    expect(courses.updated, {
      'course-1': ['description', 'objectives'],
    });
    expect(inner.docs(FirebaseCollections.courses)['course-1'], {
      'name': 'تمهيدية',
      'description': 'وصف قديم',
      'level': 'introductory',
      'isActive': false,
    });
  });

  test('reports a question that lacks its level as an update', () async {
    await _run(inner, apply: true);
    final questions = inner.docs(FirebaseCollections.questionBank);
    final id = questions.keys.first;
    questions[id]!.remove('level');

    final plans = await _run(inner, apply: false);

    expect(plans[FirebaseCollections.questionBank]!.updated, {
      id: ['level'],
    });
  });

  test('reports the orphaned documents and leaves them alone', () async {
    await _run(inner, apply: true);
    inner.docs(FirebaseCollections.courses)
      ..['second-intro'] = {'name': 'مكررة', 'level': 'introductory'}
      ..['legacy'] = {'name': 'قديمة', 'level': 'beginner'};
    inner.docs(FirebaseCollections.tajweedRules)['old-rule'] = {'name': 'قديم'};
    inner.docs(FirebaseCollections.courseRules)
      ..['legacy_old-rule'] = {'courseId': 'legacy', 'ruleId': 'old-rule'}
      ..['zz-duplicate'] = {
        'courseId': 'introductory',
        'ruleId': 'madd_tabii',
        'weight': 9,
      };
    inner.docs(FirebaseCollections.questionBank)['legacy_q1'] = {
      'courseId': 'legacy',
    };
    inner.docs(FirebaseCollections.questionAnswers)['legacy_q1'] = {
      'correctAnswer': 'أ',
    };
    inner.docs(FirebaseCollections.examSegments)['old-segment'] = {'surah': 1};
    final counts = {
      for (final entry in inner.collections.entries)
        entry.key: entry.value.length,
    };

    final plans = await _run(inner, apply: true);

    expect(plans[FirebaseCollections.courses]!.orphaned, [
      'legacy',
      'second-intro',
    ]);
    expect(plans[FirebaseCollections.tajweedRules]!.orphaned, ['old-rule']);
    expect(plans[FirebaseCollections.courseRules]!.orphaned, [
      'legacy_old-rule',
      'zz-duplicate',
    ]);
    expect(plans[FirebaseCollections.questionBank]!.orphaned, ['legacy_q1']);
    expect(plans[FirebaseCollections.questionAnswers]!.orphaned, ['legacy_q1']);
    expect(plans[FirebaseCollections.examSegments]!.orphaned, ['old-segment']);
    for (final plan in plans.values) {
      expect(plan.created, isEmpty);
      expect(plan.updated, isEmpty);
    }
    expect({
      for (final entry in inner.collections.entries)
        entry.key: entry.value.length,
    }, counts);

    final report = describeSeedPlan(plans.values.toList(), apply: false);
    expect(report, contains('Orphaned/legacy data'));
    expect(report, contains('    zz-duplicate'));
  });
}
