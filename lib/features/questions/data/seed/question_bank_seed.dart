import 'dart:math';

import '../../../courses/data/seed/curriculum_seed.dart';
import '../../../courses/domain/entities/course_level.dart';
import 'question_seed.dart';
import 'questions/foundation_questions_seed.dart';
import 'questions/letter_questions_seed.dart';
import 'questions/madd_hamz_questions_seed.dart';
import 'questions/waqf_rasm_questions_seed.dart';

/// Every theory question of the project. Hafs 'an Asim by the way of
/// al-Shatibiyyah only.
const questionSeeds = <QuestionSeed>[
  ...foundationQuestions,
  ...letterQuestions,
  ...maddHamzQuestions,
  ...waqfRasmQuestions,
];

final _introducedAt = {
  for (final rule in tajweedRuleSeeds) rule.id: rule.introducedAt,
};

/// The questions asked in the course of [level]: those on a rule the course
/// covers.
List<QuestionSeed> questionsOfLevel(CourseLevel level) => [
  for (final question in questionSeeds)
    if (_introducedAt[question.ruleId] case final introducedAt?
        when introducedAt.index <= level.index)
      question,
];

/// The level whose content [question] belongs to: the one that introduces
/// its rule.
CourseLevel questionLevel(QuestionSeed question) =>
    _introducedAt[question.ruleId] ?? CourseLevel.introductory;

/// The difficulty of [question], from 1 (easy) to 3 (hard). Unless the
/// question sets its own, it follows the level that introduces its rule.
int questionDifficulty(QuestionSeed question) =>
    question.difficulty ??
    min((_introducedAt[question.ruleId]?.index ?? 0) + 1, 3);
