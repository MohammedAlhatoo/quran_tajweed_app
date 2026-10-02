import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/exam_status.dart';
import '../../../exams/domain/entities/submission.dart';
import '../../../questions/domain/entities/exam_question.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/exam_scoring.dart';

/// Interim implementation: the theory score is calculated on the supervisor's
/// device and the security rules cannot check it against `question_answers`.
/// A trusted backend is meant to replace the grading behind the same
/// [ReviewRepository] interface.
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
  Future<Map<String, String>> fetchCorrectAnswers(
    List<String> questionIds,
  ) async {
    try {
      // Read one by one by ID: the security rules do not allow listing.
      final questionAnswers = _firestore.collection(
        FirebaseCollections.questionAnswers,
      );
      final snapshots = await Future.wait([
        for (final questionId in questionIds)
          questionAnswers.doc(questionId).get(),
      ]);
      return {
        for (final snapshot in snapshots)
          if (snapshot.data()?['correctAnswer'] case final String answer)
            snapshot.id: answer,
      };
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> approveExam({
    required String examId,
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
  }) async {
    final finalScore = ExamScoring.finalScore(
      recitationScore: recitationScore,
      theoryScore: theoryScore,
    );
    // The evaluation shares the examination's ID, so an examination can be
    // approved only once.
    final batch = _firestore.batch()
      ..set(
        _firestore.collection(FirebaseCollections.evaluations).doc(examId),
        {
          'examId': examId,
          'supervisorId': supervisorId,
          'recitationScore': recitationScore,
          'theoryScore': theoryScore,
          'finalScore': finalScore,
          'result': ExamScoring.resultOf(finalScore),
          'feedback': null,
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        },
      )
      ..update(_firestore.collection(FirebaseCollections.exams).doc(examId), {
        'status': ExamStatus.approved.value,
        'reviewedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
