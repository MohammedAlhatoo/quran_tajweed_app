import '../../domain/entities/course_level.dart';
import '../../domain/entities/tajweed_rule.dart';

export '../../domain/entities/tajweed_rule.dart'
    show TajweedCategory, TajweedRuleKind;

/// The definition of one `tajweed_rules` document.
class TajweedRuleSeed {
  const TajweedRuleSeed(
    this.category,
    this.id,
    this.name,
    this.description,
    this.introducedAt,
  ) : kind = TajweedRuleKind.recitation;

  const TajweedRuleSeed.theory(
    this.category,
    this.id,
    this.name,
    this.description,
    this.introducedAt,
  ) : kind = TajweedRuleKind.theoretical;

  const TajweedRuleSeed.hafs(
    this.category,
    this.id,
    this.name,
    this.description,
    this.introducedAt,
  ) : kind = TajweedRuleKind.hafsSpecific;

  final TajweedCategory category;

  /// The document ID. It is permanent: `course_rules`, `exam_segments` and
  /// recorded errors refer to it.
  final String id;

  final String name;
  final String description;

  /// The first course level that covers the rule. Every higher level covers
  /// it too.
  final CourseLevel introducedAt;

  final TajweedRuleKind kind;

  /// Whether the rule is performed in recitation, and so may be linked to
  /// segments later.
  bool get isRecitation => kind != TajweedRuleKind.theoretical;

  /// The fields of the `tajweed_rules` document, without its timestamps.
  Map<String, Object?> toMap() => {
    'name': name,
    'description': description,
    'category': category.value,
    'kind': kind.value,
    'isActive': true,
  };
}
