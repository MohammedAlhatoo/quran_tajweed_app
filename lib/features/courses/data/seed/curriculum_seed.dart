import '../../domain/entities/course_level.dart';
import 'rules/foundation_rules_seed.dart';
import 'rules/letter_rules_seed.dart';
import 'rules/madd_hamz_rules_seed.dart';
import 'rules/waqf_rasm_rules_seed.dart';
import 'tajweed_rule_seed.dart';

/// The definition of one `courses` document.
class CourseSeed {
  const CourseSeed(this.level, this.name, this.description);

  final CourseLevel level;
  final String name;
  final String description;

  /// The document ID used when the course does not exist yet.
  String get id => level.value;

  /// The place of the course among the four, starting at 1.
  int get order => level.index + 1;

  /// The fields of the `courses` document, without its timestamps.
  Map<String, Object?> toMap() => {
    'name': name,
    'description': description,
    'level': level.value,
    'isActive': true,
  };
}

/// The definition of one `course_rules` document.
class CourseRuleSeed {
  const CourseRuleSeed(this.level, this.ruleId, this.weight);

  final CourseLevel level;
  final String ruleId;
  final int weight;
}

/// The four approved courses, in order.
const courseSeeds = <CourseSeed>[
  CourseSeed(
    CourseLevel.introductory,
    'تمهيدية',
    'مبادئ التجويد ومخارج الحروف وصفاتها الأساسية وأحكام النون والميم والمد الطبيعي.',
  ),
  CourseSeed(
    CourseLevel.qualifying,
    'تأهيلية',
    'التوسع في المخارج والصفات والإدغام والمدود والراءات واللامات والهمز وهاء الكناية.',
  ),
  CourseSeed(
    CourseLevel.advanced,
    'عليا',
    'تفريعات المدود والوقف والابتداء والروم والإشمام والرسم وما يراعى لحفص.',
  ),
  CourseSeed(
    CourseLevel.sanad,
    'السند',
    'جميع أحكام رواية حفص عن عاصم من طريق الشاطبية بدقائق أدائها ومواضعها الخاصة.',
  ),
];

/// Every Tajweed rule of the project. Hafs 'an Asim by the way of
/// al-Shatibiyyah only.
const tajweedRuleSeeds = <TajweedRuleSeed>[
  ...foundationRules,
  ...letterRules,
  ...maddHamzRules,
  ...waqfRasmRules,
];

/// The rules covered by the course of [level]: those introduced at it or at
/// a lower level.
List<TajweedRuleSeed> rulesOfLevel(CourseLevel level) => [
  for (final rule in tajweedRuleSeeds)
    if (rule.introducedAt.index <= level.index) rule,
];

/// The weight of [rule] when segments are selected for the course of
/// [level]. It is not a student score.
///
/// A recitation rule weighs 3 in the level that introduces it, 2 in the next
/// level, and 1 after that, so each course favours segments rich in its own
/// rules. A theoretical rule is not performed in a segment and always
/// weighs 1.
int courseRuleWeight(TajweedRuleSeed rule, CourseLevel level) {
  if (!rule.isRecitation) return 1;
  return switch (level.index - rule.introducedAt.index) {
    0 => 3,
    1 => 2,
    _ => 1,
  };
}

/// The links between the four courses and their rules.
List<CourseRuleSeed> get courseRuleSeeds => [
  for (final course in courseSeeds)
    for (final rule in rulesOfLevel(course.level))
      CourseRuleSeed(
        course.level,
        rule.id,
        courseRuleWeight(rule, course.level),
      ),
];
