import 'tajweed_rule.dart';

/// The Tajweed rules of a course that belong to one chapter.
class TajweedRuleGroup {
  const TajweedRuleGroup({required this.category, required this.rules});

  /// Null for the rules whose document has no known category.
  final TajweedCategory? category;

  final List<TajweedRule> rules;

  String get label => category?.label ?? 'أحكام أخرى';

  /// [rules] grouped by chapter, in the order of [TajweedCategory]. The rules
  /// keep their order inside a chapter, and those without a known category
  /// come last. A chapter without rules is left out.
  static List<TajweedRuleGroup> byCategory(List<TajweedRule> rules) {
    final byCategory = <TajweedCategory?, List<TajweedRule>>{};
    for (final rule in rules) {
      byCategory.putIfAbsent(rule.category, () => []).add(rule);
    }
    return [
      for (final category in [...TajweedCategory.values, null])
        if (byCategory[category] case final rules?)
          TajweedRuleGroup(category: category, rules: rules),
    ];
  }
}
