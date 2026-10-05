import 'package:quran_tajweed_app/core/constants/firebase_collections.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';

/// The collections the curriculum seed owns, in the order they are reported.
const seedCollections = <String>[
  FirebaseCollections.courses,
  FirebaseCollections.tajweedRules,
  FirebaseCollections.courseRules,
  FirebaseCollections.questionBank,
  FirebaseCollections.questionAnswers,
  FirebaseCollections.examSegments,
];

/// A [SeedStore] that reads through another one and remembers what was read
/// and what was asked to be written.
///
/// Without [apply] it never writes: the writes are only remembered, so a run
/// of the seeder becomes a plan.
class RecordingSeedStore implements SeedStore {
  RecordingSeedStore(this._inner, {required this.apply});

  final SeedStore _inner;
  final bool apply;

  /// The documents found in each collection that was read.
  final Map<String, Map<String, Map<String, dynamic>>> existing = {};

  /// The documents the seeder asked to write, by collection.
  final Map<String, Map<String, Map<String, Object?>>> writes = {};

  @override
  Object get timestamp => _inner.timestamp;

  @override
  Future<Map<String, Map<String, dynamic>>> readAll(String collection) async =>
      existing[collection] = await _inner.readAll(collection);

  @override
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  ) async {
    writes.putIfAbsent(collection, () => {}).addAll(documents);
    if (apply) await _inner.writeAll(collection, documents);
  }
}

/// What a run of the seeder does, or would do, to one collection.
class CollectionPlan {
  const CollectionPlan({
    required this.collection,
    required this.existing,
    required this.created,
    required this.updated,
    required this.orphaned,
  });

  final String collection;

  /// The number of documents found before the run.
  final int existing;

  /// The IDs of the documents that do not exist yet.
  final List<String> created;

  /// The fields that change in each existing document, by its ID.
  final Map<String, List<String>> updated;

  /// The IDs of the stored documents that are not part of the curriculum.
  /// They are only reported: nothing deletes them.
  final List<String> orphaned;
}

/// The plan of every seed collection, from what [store] recorded and the
/// [result] of the seeder run over it.
List<CollectionPlan> buildSeedPlan(
  RecordingSeedStore store,
  CurriculumSeedResult result,
) => [
  for (final collection in seedCollections)
    _planOf(
      collection,
      store.existing[collection] ?? const {},
      store.writes[collection] ?? const {},
      result.documentIds[collection] ?? const {},
      store.timestamp,
    ),
];

CollectionPlan _planOf(
  String collection,
  Map<String, Map<String, dynamic>> existing,
  Map<String, Map<String, Object?>> writes,
  Set<String> curriculumIds,
  Object timestamp,
) {
  final created = <String>[];
  final updated = <String, List<String>>{};
  for (final write in writes.entries) {
    final stored = existing[write.key];
    if (stored == null) {
      created.add(write.key);
      continue;
    }
    updated[write.key] = [
      for (final field in write.value.entries)
        if (!identical(field.value, timestamp) &&
            !_sameValue(stored[field.key], field.value))
          field.key,
    ];
  }
  return CollectionPlan(
    collection: collection,
    existing: existing.length,
    created: created..sort(),
    updated: updated,
    orphaned: [
      for (final id in existing.keys)
        if (!curriculumIds.contains(id)) id,
    ]..sort(),
  );
}

bool _sameValue(Object? stored, Object? seed) {
  if (stored is! List || seed is! List) return stored == seed;
  if (stored.length != seed.length) return false;
  for (var i = 0; i < seed.length; i++) {
    if (stored[i] != seed[i]) return false;
  }
  return true;
}

/// The report printed for [plans].
String describeSeedPlan(List<CollectionPlan> plans, {required bool apply}) {
  final toCreate = apply ? 'created' : 'to create';
  final toUpdate = apply ? 'updated' : 'to update';
  final out = StringBuffer();
  for (final plan in plans) {
    out.writeln(
      '${plan.collection}: ${plan.existing} existing, '
      '${plan.created.length} $toCreate, '
      '${plan.updated.length} $toUpdate, '
      '${plan.orphaned.length} orphaned',
    );
  }

  final courses = plans.firstWhere(
    (plan) => plan.collection == FirebaseCollections.courses,
  );
  out.writeln();
  if (courses.updated.isEmpty) {
    out.writeln('Existing courses $toUpdate: none');
  } else {
    out.writeln('Existing courses $toUpdate:');
    for (final course in courses.updated.entries) {
      out.writeln('  ${course.key}: ${course.value.join(', ')}');
    }
  }

  out.writeln();
  if (plans.every((plan) => plan.orphaned.isEmpty)) {
    out.writeln('Orphaned/legacy data: none');
  } else {
    out.writeln(
      'Orphaned/legacy data (not part of the current curriculum; '
      'left untouched, review by hand):',
    );
    for (final plan in plans) {
      if (plan.orphaned.isEmpty) continue;
      out.writeln('  ${plan.collection} (${plan.orphaned.length}):');
      for (final id in plan.orphaned) {
        out.writeln('    $id');
      }
    }
  }
  return out.toString();
}
