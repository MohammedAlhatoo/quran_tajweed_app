// The checks and the scoring of the theory part of an examination. Nothing
// here reads or writes Firestore.

/** The number of questions in every examination. */
export const QUESTION_COUNT = 10;

/** The theory part is out of 20; the recitation part, out of 80. */
export const MAX_THEORY_SCORE = 20;

export const MAX_ANSWER_LENGTH = 500;

const isText = (value) => typeof value === 'string' && value.length > 0;

/**
 * The questions of an examination, in their order, from the data of its
 * `exam_questions` documents `{examId}_1` to `{examId}_10` ([documents] holds
 * them in that order, `undefined` for a missing one).
 *
 * Returns null unless all ten are stored for [examId], each at its own order
 * with a source question and its options, and no source question is repeated.
 */
export function examQuestionsFrom(examId, documents) {
  if (!Array.isArray(documents) || documents.length !== QUESTION_COUNT) {
    return null;
  }
  const questions = [];
  const questionIds = new Set();
  for (const [index, data] of documents.entries()) {
    if (data == null) return null;
    if (data.examId !== examId || data.order !== index + 1) return null;
    if (!isText(data.questionId)) return null;
    if (questionIds.has(data.questionId)) return null;
    questionIds.add(data.questionId);
    questions.push({
      order: data.order,
      questionId: data.questionId,
      options: Array.isArray(data.options)
        ? data.options.filter((option) => typeof option === 'string')
        : [],
    });
  }
  return questions;
}

/**
 * The ten answers of a submission, in the order of [questions].
 *
 * Returns null unless [answers] holds exactly one answer for each question,
 * naming its source question and one of its options.
 */
export function submittedAnswersFrom(questions, answers) {
  if (!Array.isArray(answers) || answers.length !== QUESTION_COUNT) {
    return null;
  }
  const byOrder = new Map();
  for (const answer of answers) {
    if (answer == null || typeof answer !== 'object') return null;
    if (!Number.isInteger(answer.order) || byOrder.has(answer.order)) {
      return null;
    }
    byOrder.set(answer.order, answer);
  }
  const submitted = [];
  for (const question of questions) {
    const answer = byOrder.get(question.order);
    if (answer == null || answer.questionId !== question.questionId) {
      return null;
    }
    if (!isText(answer.answer) || answer.answer.length > MAX_ANSWER_LENGTH) {
      return null;
    }
    if (!question.options.includes(answer.answer)) return null;
    submitted.push({
      order: question.order,
      questionId: question.questionId,
      answer: answer.answer,
    });
  }
  return submitted;
}

/**
 * The answer key of [questions]: `{order, questionId, correctAnswer}` for
 * each of them. [correctAnswers] maps the ID of a source question to its
 * correct answer.
 *
 * Returns null when the correct answer of a question is missing.
 */
export function answerKeyFrom(questions, correctAnswers) {
  const key = [];
  for (const question of questions) {
    const correctAnswer = correctAnswers.get(question.questionId);
    if (!isText(correctAnswer)) return null;
    key.push({
      order: question.order,
      questionId: question.questionId,
      correctAnswer,
    });
  }
  return key;
}

/**
 * The stored answer key [entries] of an examination, checked against its
 * [questions]. Returns null when it does not cover exactly these questions.
 */
export function storedAnswerKey(questions, entries) {
  if (!Array.isArray(entries) || entries.length !== questions.length) {
    return null;
  }
  const correctAnswers = new Map();
  for (const [index, entry] of entries.entries()) {
    const question = questions[index];
    if (entry == null || entry.order !== question.order) return null;
    if (entry.questionId !== question.questionId) return null;
    correctAnswers.set(entry.questionId, entry.correctAnswer);
  }
  return answerKeyFrom(questions, correctAnswers);
}

/**
 * The theory score out of 20: every question has the same share. [key] and
 * [answers] cover the same questions.
 */
export function gradeTheory(key, answers) {
  const answerByOrder = new Map(
    answers.map((answer) => [answer.order, answer.answer]),
  );
  let correctCount = 0;
  for (const entry of key) {
    if (answerByOrder.get(entry.order) === entry.correctAnswer) correctCount++;
  }
  return {
    correctCount,
    theoryScore: Math.round((correctCount * MAX_THEORY_SCORE) / key.length),
  };
}
