import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/submission_answer.dart';
import '../../domain/repositories/submission_repository.dart';

/// Submits an examination through the `submitExam` Cloud Function. The app
/// writes none of the documents of a submission itself: the security rules
/// refuse them.
class FunctionsSubmissionRepository implements SubmissionRepository {
  FunctionsSubmissionRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// The errors whose message is written by the function for the student.
  static const Set<String> _refusals = {
    'invalid-argument',
    'failed-precondition',
    'not-found',
    'permission-denied',
    'unauthenticated',
  };

  @override
  Future<void> submitExam({
    required String examId,
    required List<SubmissionAnswer> answers,
  }) async {
    try {
      await _functions.httpsCallable('submitExam').call<void>({
        'examId': examId,
        'answers': [for (final answer in answers) answer.toMap()],
      });
    } on FirebaseFunctionsException catch (e) {
      final message = e.message;
      if (_refusals.contains(e.code) && message != null && message.isNotEmpty) {
        throw AppFailure(message);
      }
      throw AppFailure.fromFirebase(e);
    }
  }
}
