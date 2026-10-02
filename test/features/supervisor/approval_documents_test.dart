import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/notifications/data/repositories/firestore_notifications_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/data/repositories/firebase_review_repository.dart';

const _exam = Exam(
  id: 'exam-1',
  studentId: 'uid-1',
  courseId: 'course-1',
  segmentId: 'segment-1',
  status: ExamStatus.pendingReview,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

Map<String, Map<String, dynamic>> _approve(int recitationScore) {
  return FirebaseReviewRepository.approvalDocuments(
    exam: _exam,
    courseName: 'تمهيدية',
    supervisorId: 'sup-1',
    recitationScore: recitationScore,
    theoryScore: 18,
  );
}

void main() {
  group('approving a result', () {
    test('a passed examination gets a certificate and a notification', () {
      final documents = _approve(60);

      expect(documents['evaluations/exam-1']!['result'], 'passed');
      final certificate = documents['certificates/exam-1']!;
      expect(certificate['studentId'], 'uid-1');
      expect(certificate['courseId'], 'course-1');
      expect(certificate['finalScore'], 78);
      expect(certificate['fileUrl'], isNull);

      final notification = documents['notifications/exam-1_result']!;
      expect(notification['userId'], 'uid-1');
      expect(notification['squareId'], isNull);
      expect(notification['isRead'], isFalse);
      expect(notification['body'], contains('ناجح'));
    });

    test('a failed examination gets a notification but no certificate', () {
      final documents = _approve(40);

      expect(documents['evaluations/exam-1']!['result'], 'failed');
      expect(documents.keys, isNot(contains('certificates/exam-1')));
      expect(documents, hasLength(2));
      expect(
        documents['notifications/exam-1_result']!['body'],
        contains('راسب'),
      );
    });

    test('the pass mark itself earns the certificate', () {
      expect(_approve(52).keys, contains('certificates/exam-1'));
      expect(_approve(51).keys, isNot(contains('certificates/exam-1')));
    });
  });

  test('a submission notifies the square of the examination, unread', () {
    final (id, data) = FirestoreNotificationsRepository.examSubmitted(
      examId: 'exam-1',
      squareId: 'square-1',
      studentName: 'أحمد',
    );

    expect(id, 'exam-1_submitted');
    expect(data['squareId'], 'square-1');
    expect(data['userId'], isNull);
    expect(data['relatedId'], 'exam-1');
    expect(data['isRead'], isFalse);
  });
}
