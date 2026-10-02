import '../entities/evaluation.dart';

/// Reads approved evaluations. All methods throw `AppFailure` on error.
abstract interface class EvaluationsRepository {
  /// Returns null when the result of [examId] is not approved yet.
  Future<Evaluation?> fetchEvaluation(String examId);

  /// The evaluations of [examIds], keyed by examination ID. An examination
  /// without an evaluation is absent.
  Future<Map<String, Evaluation>> fetchEvaluations(Iterable<String> examIds);
}
