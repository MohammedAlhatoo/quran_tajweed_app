import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../courses/domain/entities/course_level.dart';
import '../../../questions/domain/entities/question.dart';
import '../../../questions/domain/services/question_selector.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_segment.dart';
import '../../domain/entities/exam_status.dart';
import '../../domain/repositories/exams_repository.dart';
import '../../domain/services/segment_selector.dart';

/// Creates examinations from the student's device.
///
/// Interim implementation: the segment and questions are chosen on the client
/// and the "one examination per course" checks are not enforced by the
/// security rules. A trusted backend is meant to replace [startExam] behind
/// the same [ExamsRepository] interface.
///
/// The correct answers are never read here. When the examination is created,
/// the `snapshotExamAnswerKey` Cloud Function copies them into
/// `exam_answer_keys`, which students cannot read.
class FirestoreExamsRepository implements ExamsRepository {
  FirestoreExamsRepository({
    FirebaseFirestore? firestore,
    Random? random,
    this._segmentSelector = const SegmentSelector(),
    this._questionSelector = const QuestionSelector(),
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final Random _random;
  final SegmentSelector _segmentSelector;
  final QuestionSelector _questionSelector;

  CollectionReference<Map<String, dynamic>> get _exams =>
      _firestore.collection(FirebaseCollections.exams);

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static Exam? _examFrom(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return data == null
        ? null
        : Exam.fromMap(snapshot.id, data, toDate: _toDate);
  }

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) async {
    final mosqueId = student.mosqueId;
    final squareId = student.squareId;
    final regionId = student.regionId;
    if (mosqueId == null || squareId == null || regionId == null) {
      throw const AppFailure(
        'بيانات انتمائك (المسجد والمربع والمنطقة) غير مكتملة. تواصل مع الإدارة.',
      );
    }

    try {
      final existing = await _exams
          .where('studentId', isEqualTo: student.uid)
          .where('courseId', isEqualTo: courseId)
          .get();
      final courseExams = existing.docs.map(_examFrom).nonNulls.toList();
      for (final exam in courseExams) {
        // Continue the open examination with its segment and questions.
        if (exam.status.isOpen) return exam;
      }
      if (courseExams.any((exam) => exam.status.isAwaitingReview)) {
        throw const AppFailure(
          'لديك اختبار في هذه الدورة بانتظار المراجعة. '
          'لا يمكن بدء اختبار جديد قبل اعتماد نتيجته.',
        );
      }

      final courseLevel = await _fetchCourseLevel(courseId);
      if (courseLevel == null) {
        throw const AppFailure('هذه الدورة غير متاحة حاليًا.');
      }
      final ruleWeights = await _fetchCourseRuleWeights(courseId);
      final segment = _segmentSelector.select(
        courseId: courseId,
        segments: await _fetchCourseSegments(courseId),
        courseRuleWeights: ruleWeights,
        random: _random,
      );
      if (segment == null) {
        throw const AppFailure('لا توجد مقاطع متاحة لهذه الدورة حاليًا.');
      }
      final questions = _questionSelector.select(
        courseId: courseId,
        courseLevel: courseLevel,
        questions: await _fetchCourseQuestions(courseId),
        courseRuleWeights: ruleWeights,
        random: _random,
      );
      if (questions == null) {
        throw const AppFailure('لا توجد أسئلة كافية لهذه الدورة حاليًا.');
      }

      final examRef = _exams.doc();
      final batch = _firestore.batch()
        ..set(examRef, {
          'studentId': student.uid,
          'courseId': courseId,
          'segmentId': segment.id,
          'status': ExamStatus.inProgress.value,
          'mosqueId': mosqueId,
          'squareId': squareId,
          'regionId': regionId,
          'startedAt': FieldValue.serverTimestamp(),
          'submittedAt': null,
          'reviewedAt': null,
          'approvedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      final examQuestions = _firestore.collection(
        FirebaseCollections.examQuestions,
      );
      for (final (index, question) in questions.indexed) {
        final order = index + 1;
        // The exact question shown to the student is preserved here.
        batch.set(examQuestions.doc('${examRef.id}_$order'), {
          'examId': examRef.id,
          'studentId': student.uid,
          'questionId': question.id,
          'order': order,
          'type': question.type,
          'question': question.question,
          'options': question.options,
        });
      }
      await batch.commit();

      return Exam(
        id: examRef.id,
        studentId: student.uid,
        courseId: courseId,
        segmentId: segment.id,
        status: ExamStatus.inProgress,
        mosqueId: mosqueId,
        squareId: squareId,
        regionId: regionId,
        startedAt: DateTime.now(),
      );
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<Exam?> fetchExam(String examId) async {
    try {
      return _examFrom(await _exams.doc(examId).get());
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.examSegments)
          .doc(segmentId)
          .get();
      final data = snapshot.data();
      return data == null ? null : ExamSegment.fromMap(snapshot.id, data);
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async {
    try {
      final snapshot = await _exams
          .where('studentId', isEqualTo: studentId)
          .get();
      final exams = snapshot.docs.map(_examFrom).nonNulls.toList();
      // Sorted here to avoid requiring a composite index.
      final oldest = DateTime.fromMillisecondsSinceEpoch(0);
      exams.sort(
        (a, b) => (b.startedAt ?? oldest).compareTo(a.startedAt ?? oldest),
      );
      return exams;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  /// Returns null when the course does not exist or has no valid level.
  Future<CourseLevel?> _fetchCourseLevel(String courseId) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.courses)
        .doc(courseId)
        .get();
    return CourseLevel.fromValue(snapshot.data()?['level']);
  }

  /// The weight of each Tajweed rule of the course, from `course_rules`.
  Future<Map<String, double>> _fetchCourseRuleWeights(String courseId) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.courseRules)
        .where('courseId', isEqualTo: courseId)
        .get();
    final weights = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['ruleId'] case final String ruleId) {
        final weight = data['weight'];
        weights[ruleId] = weight is num ? weight.toDouble() : 1;
      }
    }
    return weights;
  }

  Future<List<ExamSegment>> _fetchCourseSegments(String courseId) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.examSegments)
        .where('courseIds', arrayContains: courseId)
        .get();
    return [
      for (final doc in snapshot.docs) ?ExamSegment.fromMap(doc.id, doc.data()),
    ];
  }

  Future<List<Question>> _fetchCourseQuestions(String courseId) async {
    final snapshot = await _firestore
        .collection(FirebaseCollections.questionBank)
        .where('courseId', isEqualTo: courseId)
        .get();
    return [
      for (final doc in snapshot.docs) ?Question.fromMap(doc.id, doc.data()),
    ];
  }
}
