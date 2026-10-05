import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/evaluation.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/recitation_error.dart';

DateTime? _toDate(Object? value) => value is DateTime ? value : null;

Map<String, dynamic> _evaluation([Map<String, dynamic> extra = const {}]) => {
  'examId': 'exam-1',
  'supervisorId': 'sup-1',
  'recitationScore': 60,
  'theoryScore': 18,
  'finalScore': 78,
  'result': 'passed',
  'status': 'approved',
  ...extra,
};

void main() {
  group('Evaluation.fromMap', () {
    test('reads the scores, the notes and the errors in order', () {
      final recordedAt = DateTime(2026, 10, 3);
      final evaluation = Evaluation.fromMap(
        'exam-1',
        _evaluation({
          'feedback': 'راجع أحكام النون الساكنة',
          'detailedErrors': [
            {
              'id': 'error-1',
              'ruleId': 'rule-a',
              'ruleName': 'الإخفاء',
              'ayahNumber': 3,
              'word': 'أنتم',
              'description': 'لم تُخفَ النون',
              'createdAt': recordedAt,
            },
            {
              'id': 'error-2',
              'ruleId': 'rule-b',
              'ruleName': null,
              'ayahNumber': null,
              'word': null,
              'description': '',
              'createdAt': recordedAt,
            },
          ],
        }),
        toDate: _toDate,
      )!;

      expect(evaluation.recitationScore, 60);
      expect(evaluation.theoryScore, 18);
      expect(evaluation.finalScore, 78);
      expect(evaluation.passed, isTrue);
      expect(evaluation.feedback, 'راجع أحكام النون الساكنة');
      expect(evaluation.detailedErrors, hasLength(2));

      final first = evaluation.detailedErrors.first;
      expect(first.id, 'error-1');
      expect(first.ruleId, 'rule-a');
      expect(first.ruleName, 'الإخفاء');
      expect(first.ayahNumber, 3);
      expect(first.word, 'أنتم');
      expect(first.description, 'لم تُخفَ النون');
      expect(first.createdAt, recordedAt);
      expect(first.position, 'الآية 3 · «أنتم»');

      final second = evaluation.detailedErrors.last;
      expect(second.ruleName, isNull);
      expect(second.position, isNull);
      expect(second.description, isEmpty);
    });

    test('an evaluation saved before the report has no notes or errors', () {
      final evaluation = Evaluation.fromMap(
        'exam-1',
        _evaluation({'feedback': null}),
        toDate: _toDate,
      )!;

      expect(evaluation.feedback, isNull);
      expect(evaluation.detailedErrors, isEmpty);
    });

    test('an evaluation that is not approved yet is not a result', () {
      // As the submission writes it: the theory score only.
      expect(
        Evaluation.fromMap('exam-1', {
          'examId': 'exam-1',
          'supervisorId': null,
          'recitationScore': null,
          'theoryScore': 18,
          'correctCount': 9,
          'finalScore': null,
          'result': null,
          'feedback': null,
          'detailedErrors': <Object>[],
          'status': 'pending',
          'reviewedAt': null,
          'approvedAt': null,
        }, toDate: _toDate),
        isNull,
      );
    });

    test('skips an error without an ID or a rule', () {
      final evaluation = Evaluation.fromMap(
        'exam-1',
        _evaluation({
          'feedback': '   ',
          'detailedErrors': [
            'not an error',
            {'id': 'error-1', 'description': 'بلا قاعدة'},
            {'ruleId': 'rule-a', 'description': 'بلا معرّف'},
            {'id': 'error-2', 'ruleId': 'rule-a'},
          ],
        }),
        toDate: _toDate,
      )!;

      expect(evaluation.feedback, isNull);
      expect(evaluation.detailedErrors.single.id, 'error-2');
      expect(evaluation.detailedErrors.single.description, isEmpty);
    });
  });

  test('RecitationError.toMap stores every field, empty ones as null', () {
    final recordedAt = DateTime(2026, 10, 3);
    final error = RecitationError(
      id: 'error-1',
      ruleId: 'rule-a',
      description: '',
      ayahNumber: 7,
      createdAt: recordedAt,
    );

    expect(error.toMap(fromDate: (date) => date), {
      'id': 'error-1',
      'ruleId': 'rule-a',
      'ruleName': null,
      'ayahNumber': 7,
      'word': null,
      'description': '',
      'createdAt': recordedAt,
    });
    expect(error.position, 'الآية 7');
  });

  test('TajweedRule.fromMap needs a name', () {
    expect(TajweedRule.fromMap('rule-a', {'name': 'الإخفاء'})!.name, 'الإخفاء');
    expect(TajweedRule.fromMap('rule-a', {'name': ''}), isNull);
    expect(TajweedRule.fromMap('rule-a', const {}), isNull);
  });
}
