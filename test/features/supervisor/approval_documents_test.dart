import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/recitation_error.dart';
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

/// The documents created by an approval, with a saved theory score of 18.
Map<String, Map<String, dynamic>> _approve(int recitationScore) {
  return FirebaseReviewRepository.approvalDocuments(
    exam: _exam,
    courseName: 'تمهيدية',
    recitationScore: recitationScore,
    theoryScore: 18,
  );
}

/// The evaluation of an approval, with a theory score of 18.
Map<String, dynamic> _evaluation(int recitationScore) {
  return FirebaseReviewRepository.evaluationApproval(
    examId: 'exam-1',
    supervisorId: 'sup-1',
    recitationScore: recitationScore,
    theoryScore: 18,
  );
}

void main() {
  group('approving a result', () {
    test('a passed examination gets a certificate and a notification', () {
      final documents = _approve(60);

      expect(_evaluation(60)['result'], 'passed');
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

      expect(_evaluation(40)['result'], 'failed');
      expect(documents.keys, ['notifications/exam-1_result']);
      expect(
        documents['notifications/exam-1_result']!['body'],
        contains('راسب'),
      );
    });

    test('the evaluation holds the notes and the detailed errors', () {
      final recordedAt = DateTime(2026, 10, 3, 9);
      final evaluation = FirebaseReviewRepository.evaluationApproval(
        examId: 'exam-1',
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

      expect(evaluation['supervisorId'], 'sup-1');
      expect(evaluation['recitationScore'], 60);
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
    });

    test('the evaluation holds exactly the fields the rules accept', () {
      expect(_evaluation(60)['examId'], 'exam-1');
      expect(_evaluation(60)['theoryScore'], 18);
      expect(_evaluation(60).keys.toSet(), {
        'examId',
        'supervisorId',
        'recitationScore',
        'theoryScore',
        'finalScore',
        'result',
        'feedback',
        'detailedErrors',
        'status',
        'reviewedAt',
        'approvedAt',
      });
      expect(_approve(60).keys, isNot(contains('evaluations/exam-1')));
    });

    test('the final score is the recitation plus the theory score', () {
      final evaluation = FirebaseReviewRepository.evaluationApproval(
        examId: 'exam-1',
        supervisorId: 'sup-1',
        recitationScore: 55,
        theoryScore: 14,
      );

      expect(evaluation['finalScore'], 69);
      expect(evaluation['result'], 'failed');
    });

    test('an evaluation without notes or errors stores an empty list', () {
      final evaluation = _evaluation(60);

      expect(evaluation['feedback'], isNull);
      expect(evaluation['detailedErrors'], isEmpty);
    });

    test('the pass mark itself earns the certificate', () {
      expect(_approve(52).keys, contains('certificates/exam-1'));
      expect(_approve(51).keys, isNot(contains('certificates/exam-1')));
    });
  });

  group('the answer key of an examination', () {
    test('is read by the order of the question', () {
      expect(
        FirebaseReviewRepository.answerKeyFrom({
          'examId': 'exam-1',
          'answers': [
            {'order': 1, 'questionId': 'q1', 'correctAnswer': 'أ'},
            {'order': 2, 'questionId': 'q2', 'correctAnswer': 'ب'},
            {'order': 3, 'questionId': 'q3'},
            'not an answer',
          ],
        }),
        {1: 'أ', 2: 'ب'},
      );
    });

    test('is empty for an examination without one', () {
      expect(FirebaseReviewRepository.answerKeyFrom(null), isEmpty);
      expect(FirebaseReviewRepository.answerKeyFrom(const {}), isEmpty);
    });
  });
}
