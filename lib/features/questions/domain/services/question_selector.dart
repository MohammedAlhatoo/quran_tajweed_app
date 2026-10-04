import 'dart:math';

import '../../../courses/domain/entities/course_level.dart';
import '../entities/question.dart';

/// Chooses the theory questions of a new examination.
///
/// Pure logic with no Firebase dependency, so it can move to a trusted backend
/// unchanged.
class QuestionSelector {
  const QuestionSelector();

  /// The number of theory questions in every examination.
  static const int examQuestionCount = 10;

  /// How the questions of an examination are shared between the content of
  /// the course's own level and that of the levels below it, out of
  /// [examQuestionCount]. The own level always holds the largest share.
  static const Map<CourseLevel, Map<CourseLevel, int>> levelShares = {
    CourseLevel.introductory: {CourseLevel.introductory: 10},
    CourseLevel.qualifying: {
      CourseLevel.qualifying: 7,
      CourseLevel.introductory: 3,
    },
    CourseLevel.advanced: {
      CourseLevel.advanced: 6,
      CourseLevel.qualifying: 3,
      CourseLevel.introductory: 1,
    },
    CourseLevel.sanad: {
      CourseLevel.sanad: 5,
      CourseLevel.advanced: 3,
      CourseLevel.qualifying: 1,
      CourseLevel.introductory: 1,
    },
  };

  /// The number of questions taken from the content of each level in an
  /// examination of [count] questions of the course of [courseLevel]: the
  /// [levelShares] scaled to [count], the remainder going to the highest
  /// levels first.
  static Map<CourseLevel, int> quotasOf(
    CourseLevel courseLevel, {
    int count = examQuestionCount,
  }) {
    final shares = levelShares[courseLevel]!;
    final quotas = {
      for (final entry in shares.entries)
        entry.key: entry.value * count ~/ examQuestionCount,
    };
    var remainder = count - quotas.values.fold(0, (sum, quota) => sum + quota);
    for (final level in _downFrom(courseLevel)) {
      if (remainder == 0) break;
      quotas[level] = quotas[level]! + 1;
      remainder--;
    }
    return quotas;
  }

  /// Picks [count] active questions of [courseId], shared between the levels
  /// by [quotasOf] and then put in a random order.
  ///
  /// Within the content of one level the questions are spread across the
  /// Tajweed rules: rules are visited in a random order that favors heavier
  /// [courseRuleWeights], taking one unused question from each rule per round.
  ///
  /// When a level has fewer questions than its quota, the shortfall is taken
  /// from the nearest lower level, and from the higher ones only when the
  /// lower ones run out. A question of a level above [courseLevel] counts as
  /// one of [courseLevel].
  ///
  /// Returns null when fewer than [count] questions are available.
  List<Question>? select({
    required String courseId,
    required CourseLevel courseLevel,
    required List<Question> questions,
    required Map<String, double> courseRuleWeights,
    required Random random,
    int count = examQuestionCount,
  }) {
    final byLevel = <CourseLevel, Map<String, List<Question>>>{};
    var available = 0;
    for (final question in questions) {
      if (!question.isActive || question.courseId != courseId) continue;
      final level = question.level.index > courseLevel.index
          ? courseLevel
          : question.level;
      byLevel
          .putIfAbsent(level, () => {})
          .putIfAbsent(question.ruleId, () => [])
          .add(question);
      available++;
    }
    if (available < count) return null;

    final quotas = quotasOf(courseLevel, count: count);
    final selected = <Question>[];
    var shortfall = 0;
    for (final level in _downFrom(courseLevel)) {
      final wanted = quotas[level]! + shortfall;
      final taken = _take(byLevel[level], wanted, courseRuleWeights, random);
      selected.addAll(taken);
      shortfall = wanted - taken.length;
    }
    // The lower levels ran out: what is left can only be in the higher ones.
    for (final level in _downFrom(courseLevel)) {
      if (shortfall == 0) break;
      final taken = _take(byLevel[level], shortfall, courseRuleWeights, random);
      selected.addAll(taken);
      shortfall -= taken.length;
    }
    return selected..shuffle(random);
  }

  /// The levels from [level] down to the introductory one.
  static Iterable<CourseLevel> _downFrom(CourseLevel level) =>
      CourseLevel.values.sublist(0, level.index + 1).reversed;

  /// Removes up to [count] questions from [byRule] and returns them, spread
  /// across its rules.
  List<Question> _take(
    Map<String, List<Question>>? byRule,
    int count,
    Map<String, double> weights,
    Random random,
  ) {
    final taken = <Question>[];
    if (byRule == null || count <= 0) return taken;

    for (final group in byRule.values) {
      group.shuffle(random);
    }
    final ruleOrder = _weightedOrder(byRule.keys.toList(), weights, random);
    var left = byRule.values.fold(0, (sum, group) => sum + group.length);
    while (taken.length < count && left > 0) {
      for (final ruleId in ruleOrder) {
        final group = byRule[ruleId]!;
        if (group.isEmpty) continue;
        taken.add(group.removeLast());
        left--;
        if (taken.length == count) break;
      }
    }
    return taken;
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
