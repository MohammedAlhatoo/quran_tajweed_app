import 'dart:math';

import '../entities/exam_segment.dart';

/// Chooses the Quran segment of a new examination.
///
/// Pure logic with no Firebase dependency, so it can move to a trusted backend
/// unchanged.
class SegmentSelector {
  const SegmentSelector();

  /// The selection weight of [segment] for a course:
  /// `ruleDensity × Σ weight of the course rules found in the segment`.
  ///
  /// [courseRuleWeights] maps each rule of the course to its weight.
  static double weightOf(
    ExamSegment segment,
    Map<String, double> courseRuleWeights,
  ) {
    var rulesWeight = 0.0;
    for (final ruleId in segment.ruleIds.toSet()) {
      rulesWeight += courseRuleWeights[ruleId] ?? 0;
    }
    return max(segment.ruleDensity, 0) * max(rulesWeight, 0);
  }

  /// Picks one of the active [segments] that belong to [courseId], at random
  /// with probability proportional to [weightOf]. Returns null when no
  /// segment has a positive weight.
  ExamSegment? select({
    required String courseId,
    required List<ExamSegment> segments,
    required Map<String, double> courseRuleWeights,
    required Random random,
  }) {
    final candidates = <(ExamSegment, double)>[];
    var total = 0.0;
    for (final segment in segments) {
      if (!segment.isActive || !segment.courseIds.contains(courseId)) continue;
      final weight = weightOf(segment, courseRuleWeights);
      if (weight <= 0) continue;
      candidates.add((segment, weight));
      total += weight;
    }
    if (candidates.isEmpty) return null;

    var target = random.nextDouble() * total;
    for (final (segment, weight) in candidates) {
      target -= weight;
      if (target < 0) return segment;
    }
    // Floating-point rounding can leave a tiny remainder.
    return candidates.last.$1;
  }
}
