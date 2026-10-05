import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/tajweed_rule.dart';
import '../../domain/repositories/courses_repository.dart';

class FirestoreCoursesRepository implements CoursesRepository {
  FirestoreCoursesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Firestore allows at most this many values in a `whereIn` filter.
  static const int _whereInLimit = 30;

  @override
  Future<List<Course>> fetchActiveCourses() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.courses)
          .where('isActive', isEqualTo: true)
          .get();
      final courses = [
        for (final doc in snapshot.docs) ?Course.fromMap(doc.id, doc.data()),
      ];
      courses.sort((a, b) => a.level.index.compareTo(b.level.index));
      return courses;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<Course?> fetchCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.courses)
          .doc(courseId)
          .get();
      final data = snapshot.data();
      if (data == null || data['isActive'] != true) return null;
      return Course.fromMap(snapshot.id, data);
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<List<TajweedRule>> fetchCourseRules(String courseId) async {
    try {
      final links = await _firestore
          .collection(FirebaseCollections.courseRules)
          .where('courseId', isEqualTo: courseId)
          .get();
      final ruleIds = {
        for (final doc in links.docs)
          if (doc.data()['ruleId'] case final String ruleId) ruleId,
      }.toList();

      final rules = <TajweedRule>[];
      for (var i = 0; i < ruleIds.length; i += _whereInLimit) {
        final end = (i + _whereInLimit).clamp(0, ruleIds.length);
        final snapshot = await _firestore
            .collection(FirebaseCollections.tajweedRules)
            .where(FieldPath.documentId, whereIn: ruleIds.sublist(i, end))
            .get();
        rules.addAll([
          for (final doc in snapshot.docs)
            ?TajweedRule.fromMap(doc.id, doc.data()),
        ]);
      }
      return rules;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
