import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../domain/entities/exam_status.dart';
import '../../domain/entities/submission_answer.dart';
import '../../domain/repositories/submission_repository.dart';
import 'cloudinary_recording_repository.dart';

/// Submits an examination from the student's device, in one batch the
/// security rules accept only as a whole and only once.
///
/// Nothing is graded here: students cannot read the correct answers. The
/// theory score is calculated on the supervisor's device at the review.
class FirestoreSubmissionRepository implements SubmissionRepository {
  FirestoreSubmissionRepository({
    FirebaseFirestore? firestore,
    Future<String?> Function(String examId)? recordingUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _recordingUrl = recordingUrl ?? uploadedRecordingUrl;

  final FirebaseFirestore _firestore;

  /// The link of the uploaded recitation of an examination.
  final Future<String?> Function(String examId) _recordingUrl;

  @override
  Future<void> submitExam({
    required String examId,
    required List<SubmissionAnswer> answers,
  }) async {
    final recordingUrl = await _recordingUrl(examId);
    if (recordingUrl == null) {
      throw const AppFailure('ارفع تسجيل التلاوة قبل إرسال الاختبار.');
    }
    try {
      final examRef = _firestore
          .collection(FirebaseCollections.exams)
          .doc(examId);
      final exam = (await examRef.get()).data();
      if (exam == null) throw const AppFailure('هذا الاختبار غير موجود.');
      if (exam['status'] != ExamStatus.inProgress.value) {
        throw const AppFailure('تم إرسال هذا الاختبار من قبل.');
      }
      final studentId = exam['studentId'] as String;
      final student = await _firestore
          .collection(FirebaseCollections.users)
          .doc(studentId)
          .get();

      final batch = _firestore.batch()
        ..set(_firestore.collection(FirebaseCollections.submissions).doc(examId), {
          'examId': examId,
          'studentId': studentId,
          'recordingUrl': recordingUrl,
          'answers': [for (final answer in answers) answer.toMap()],
          'submittedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(examRef, {
          'status': ExamStatus.pendingReview.value,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      // The notification goes to the square the examination was started in,
      // which is the square whose supervisor reviews it.
      final squareId = exam['squareId'];
      if (squareId is String && squareId.isNotEmpty) {
        batch.set(
          _firestore
              .collection(FirebaseCollections.notifications)
              .doc('${examId}_submitted'),
          {
            'userId': null,
            'squareId': squareId,
            'title': 'اختبار جديد يحتاج مراجعة',
            'body':
                'أرسل الطالب ${student.data()?['name'] ?? ''} اختبارًا '
                'بانتظار مراجعتك.',
            'type': AppNotification.examSubmitted,
            'relatedId': examId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
