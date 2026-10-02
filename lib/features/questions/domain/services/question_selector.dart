import 'dart:math';

import '../entities/question.dart';

/// Chooses the theory questions of a new examination.
///
/// Pure logic with no Firebase dependency, so it can move to a trusted backend
/// unchanged.
class QuestionSelector {
  const QuestionSelector();

  /// The number of theory questions in every examination.
  static const int examQuestionCount = 10;

  /// Picks [count] active questions of [courseId], spread across the Tajweed
  /// rules: rules are visited in a random order that favors heavier
  /// [courseRuleWeights], taking one unused question from each rule per round.
  ///
  /// Returns null when fewer than [count] questions are available.
  List<Question>? select({
    required String courseId,
    required List<Question> questions,
    required Map<String, double> courseRuleWeights,
    required Random random,
    int count = examQuestionCount,
  }) {
    final byRule = <String, List<Question>>{};
    var available = 0;
    for (final question in questions) {
      if (!question.isActive || question.courseId != courseId) continue;
      byRule.putIfAbsent(question.ruleId, () => []).add(question);
      available++;
    }
    if (available < count) return null;

    for (final group in byRule.values) {
      group.shuffle(random);
    }
    final ruleOrder = _weightedOrder(
      byRule.keys.toList(),
      courseRuleWeights,
      random,
    );

    final selected = <Question>[];
    while (selected.length < count) {
      for (final ruleId in ruleOrder) {
        final group = byRule[ruleId]!;
        if (group.isEmpty) continue;
        selected.add(group.removeLast());
        if (selected.length == count) break;
      }
    }
    return selected;
  }

  /// Orders [ruleIds] randomly so that heavier rules tend to come first
  /// (weighted sampling without replacement). Rules without a course weight
  /// count as weight 1.
  List<String> _weightedOrder(
    List<String> ruleIds,
    Map<String, double> weights,
    Random random,
  ) {
    final keys = <String, double>{
      for (final ruleId in ruleIds)
        ruleId: pow(
          // Avoid 0, whose logarithm is undefined.
          max(random.nextDouble(), 1e-12),
          1 / max(weights[ruleId] ?? 1, 1e-6),
        ).toDouble(),
    };
    return ruleIds..sort((a, b) => keys[b]!.compareTo(keys[a]!));
  }
}
