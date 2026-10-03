import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/recitation_error.dart';
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

    test('the evaluation holds the notes and the detailed errors', () {
      final recordedAt = DateTime(2026, 10, 3, 9);
      final documents = FirebaseReviewRepository.approvalDocuments(
        exam: _exam,
        courseName: 'تمهيدية',
        supervisorId: 'sup-1',
        recitationScore: 60,
        theoryScore: 18,
        feedback: 'راجع أحكام النون الساكنة',
        errors: [
          RecitationError(
            id: 'error-1',
            ruleId: 'rule-a',
            ruleName: 'الإخفاء',
            ayahNumber: 3,
            word: 'أنتم',
            description: 'لم تُخفَ النون',
            createdAt: recordedAt,
          ),
          RecitationError(
            id: 'error-2',
            ruleId: 'rule-b',
            description: '',
            createdAt: recordedAt,
          ),
        ],
      );

      final evaluation = documents['evaluations/exam-1']!;
      expect(evaluation['supervisorId'], 'sup-1');
      expect(evaluation['recitationScore'], 60);
      expect(evaluation['theoryScore'], 18);
      expect(evaluation['finalScore'], 78);
      expect(evaluation['result'], 'passed');
      expect(evaluation['status'], 'approved');
      expect(evaluation['feedback'], 'راجع أحكام النون الساكنة');
      expect(evaluation['detailedErrors'], [
        {
          'id': 'error-1',
          'ruleId': 'rule-a',
          'ruleName': 'الإخفاء',
          'ayahNumber': 3,
          'word': 'أنتم',
          'description': 'لم تُخفَ النون',
          'createdAt': Timestamp.fromDate(recordedAt),
        },
        {
          'id': 'error-2',
          'ruleId': 'rule-b',
          'ruleName': null,
          'ayahNumber': null,
          'word': null,
          'description': '',
          'createdAt': Timestamp.fromDate(recordedAt),
        },
      ]);
      // The certificate and the notification are issued as before.
      expect(documents.keys, contains('certificates/exam-1'));
      expect(documents.keys, contains('notifications/exam-1_result'));
    });

    test('an evaluation without notes or errors stores an empty list', () {
      final evaluation = _approve(60)['evaluations/exam-1']!;

      expect(evaluation['feedback'], isNull);
      expect(evaluation['detailedErrors'], isEmpty);
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
