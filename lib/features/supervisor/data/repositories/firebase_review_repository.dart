import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../certificates/data/repositories/firestore_certificates_repository.dart';
import '../../../courses/domain/entities/tajweed_rule.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/exam_status.dart';
import '../../../exams/domain/entities/recitation_error.dart';
import '../../../exams/domain/entities/submission.dart';
import '../../../notifications/data/repositories/firestore_notifications_repository.dart';
import '../../../questions/domain/entities/exam_question.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/exam_scoring.dart';

/// The theory score is never calculated or written here: the `submitExam`
/// Cloud Function saves it in the evaluation when the student submits, and
/// the security rules refuse any change to it.
class FirebaseReviewRepository implements ReviewRepository {
  FirebaseReviewRepository({
    required StorageService storageService,
    FirebaseFirestore? firestore,
  }) : _storage = storageService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final StorageService _storage;
  final FirebaseFirestore _firestore;

  /// The number of questions in every examination.
  static const int _questionCount = 10;

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  Future<List<Exam>> fetchPendingExams(String squareId) async {
    try {
      // The security rules allow a supervisor to read only the examinations
      // of their square, so the query must filter on squareId.
      final snapshot = await _firestore
          .collection(FirebaseCollections.exams)
          .where('squareId', isEqualTo: squareId)
          .where(
            'status',
            whereIn: [
              for (final status in ExamStatus.values)
                if (status.isAwaitingReview) status.value,
            ],
          )
          .get();
      final exams = [
        for (final doc in snapshot.docs)
          ?Exam.fromMap(doc.id, doc.data(), toDate: _toDate),
      ];
      // Sorted here to avoid requiring a composite index.
      final oldest = DateTime.fromMillisecondsSinceEpoch(0);
      exams.sort(
        (a, b) => (a.submittedAt ?? oldest).compareTo(b.submittedAt ?? oldest),
      );
      return exams;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<List<Exam>> fetchReviewedExams(String squareId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.exams)
          .where('squareId', isEqualTo: squareId)
          .where('status', isEqualTo: ExamStatus.approved.value)
          .get();
      final exams = [
        for (final doc in snapshot.docs)
          ?Exam.fromMap(doc.id, doc.data(), toDate: _toDate),
      ];
      // Sorted here to avoid requiring a composite index.
      final oldest = DateTime.fromMillisecondsSinceEpoch(0);
      exams.sort(
        (a, b) => (b.submittedAt ?? oldest).compareTo(a.submittedAt ?? oldest),
      );
      return exams;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<AppUser?> fetchStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(studentId)
          .get();
      final data = snapshot.data();
      return data == null ? null : AppUser.fromMap(snapshot.id, data);
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<Submission?> fetchSubmission(String examId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.submissions)
          .doc(examId)
          .get();
      final data = snapshot.data();
      return data == null
          ? null
          : Submission.fromMap(snapshot.id, data, toDate: _toDate);
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<List<ExamQuestion>> fetchExamQuestions(String examId) async {
    try {
      // Read one by one by ID: the security rules check the examination of
      // each record, which a query cannot satisfy.
      final examQuestions = _firestore.collection(
        FirebaseCollections.examQuestions,
      );
      final snapshots = await Future.wait([
        for (var order = 1; order <= _questionCount; order++)
          examQuestions.doc('${examId}_$order').get(),
      ]);
      return [
        for (final snapshot in snapshots)
          if (snapshot.data() case final data?)
            ?ExamQuestion.fromMap(snapshot.id, data),
      ];
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<int?> fetchTheoryScore(String examId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.evaluations)
          .doc(examId)
          .get();
      final theoryScore = snapshot.data()?['theoryScore'];
      return theoryScore is int ? theoryScore : null;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<Map<int, String>> fetchAnswerKey(String examId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.examAnswerKeys)
          .doc(examId)
          .get();
      return answerKeyFrom(snapshot.data());
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  /// The correct answers of an `exam_answer_keys` document, keyed by the
  /// order of the question. Empty when [data] is null or holds none.
  static Map<int, String> answerKeyFrom(Map<String, dynamic>? data) {
    final answers = data?['answers'];
    return {
      if (answers is List)
        for (final answer in answers)
          if (answer case {
            'order': final int order,
            'correctAnswer': final String correctAnswer,
          })
            order: correctAnswer,
    };
  }

  @override
  Future<List<TajweedRule>> fetchTajweedRules() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.tajweedRules)
          .get();
      // Only an active rule performed in recitation can be recorded as a
      // recitation error.
      final rules = [
        for (final doc in snapshot.docs)
          if (TajweedRule.fromMap(doc.id, doc.data()) case final rule?
              when rule.isActive && rule.isRecitation)
            rule,
      ];
      rules.sort((a, b) => a.name.compareTo(b.name));
      return rules;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  /// What the supervisor adds to the pending evaluation of an examination to
  /// approve its result. [theoryScore] is the saved theory score; it is used
  /// for the final score and is not among the fields, so it is never written.
  static Map<String, dynamic> evaluationApproval({
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
    String? feedback,
    List<RecitationError> errors = const [],
  }) {
    final finalScore = ExamScoring.finalScore(
      recitationScore: recitationScore,
      theoryScore: theoryScore,
    );
    return {
      'supervisorId': supervisorId,
      'recitationScore': recitationScore,
      'finalScore': finalScore,
      'result': ExamScoring.resultOf(finalScore),
      'feedback': feedback,
      // Kept inside the evaluation: the errors are written once with it and
      // read with it. A server timestamp cannot be written inside a list,
      // so each error carries the time it was recorded on the device.
      'detailedErrors': [
        for (final error in errors) error.toMap(fromDate: Timestamp.fromDate),
      ],
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'approvedAt': FieldValue.serverTimestamp(),
    };
  }

  /// The documents created when the result of [exam] is approved, by path:
  /// the student's notification and, only when the result is passed, the
  /// certificate.
  static Map<String, Map<String, dynamic>> approvalDocuments({
    required Exam exam,
    required String courseName,
    required int recitationScore,
    required int theoryScore,
  }) {
    final examId = exam.id;
    final finalScore = ExamScoring.finalScore(
      recitationScore: recitationScore,
      theoryScore: theoryScore,
    );
    final passed = ExamScoring.resultOf(finalScore) == ExamScoring.passed;
    final (
      notificationId,
      notification,
    ) = FirestoreNotificationsRepository.examApproved(
      examId: examId,
      studentId: exam.studentId,
      courseName: courseName,
      finalScore: finalScore,
      passed: passed,
    );

    return {
      '${FirebaseCollections.notifications}/$notificationId': notification,
      // A failed examination never gets a certificate.
      if (passed)
        '${FirebaseCollections.certificates}/$examId':
            FirestoreCertificatesRepository.document(
              examId: examId,
              studentId: exam.studentId,
              courseId: exam.courseId,
              finalScore: finalScore,
            ),
    };
  }

  @override
  Future<void> approveExam({
    required Exam exam,
    required String courseName,
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
    required String? feedback,
    required List<RecitationError> errors,
  }) async {
    // One batch: the result, its notification and its certificate exist only
    // together with the approved examination.
    final batch = _firestore.batch()
      ..update(_firestore.collection(FirebaseCollections.exams).doc(exam.id), {
        'status': ExamStatus.approved.value,
        'reviewedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      // An update, never a creation: only an examination that was submitted
      // and graded has an evaluation to approve, and it is approved once.
      ..update(
        _firestore.collection(FirebaseCollections.evaluations).doc(exam.id),
        evaluationApproval(
          supervisorId: supervisorId,
          recitationScore: recitationScore,
          theoryScore: theoryScore,
          feedback: feedback,
          errors: errors,
        ),
      );
    final documents = approvalDocuments(
      exam: exam,
      courseName: courseName,
      recitationScore: recitationScore,
      theoryScore: theoryScore,
    );
    for (final MapEntry(key: path, value: data) in documents.entries) {
      batch.set(_firestore.doc(path), data);
    }
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<String> downloadRecording({
    required String examId,
    required String recordingPath,
  }) async {
    final file = File('${Directory.systemTemp.path}/review_$examId.m4a');
    try {
      await _storage.downloadFile(path: recordingPath, file: file);
      return file.path;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    } on FileSystemException {
      throw const AppFailure('تعذّر حفظ التسجيل على الجهاز.');
    }
  }
}
