// What the examination functions read and write in Firestore.
import { FieldValue } from 'firebase-admin/firestore';

import {
  QUESTION_COUNT,
  answerKeyFrom,
  examQuestionsFrom,
} from './grading.js';

export const collections = {
  users: 'users',
  exams: 'exams',
  examQuestions: 'exam_questions',
  examAnswerKeys: 'exam_answer_keys',
  questionAnswers: 'question_answers',
  submissions: 'submissions',
  evaluations: 'evaluations',
  notifications: 'notifications',
};

/** The statuses of an examination that is submitted and not approved yet. */
export const awaitingReviewStatuses = [
  'submitted',
  'pending_review',
  'under_review',
];

/** Where an answer key was copied from `question_answers`. */
export const keySources = {
  examCreated: 'exam_created',
  submission: 'submission',
  backfill: 'backfill',
};

/** The ten `exam_questions` documents of [examId], in their order. */
export function examQuestionRefs(db, examId) {
  return Array.from({ length: QUESTION_COUNT }, (_, index) =>
    db.doc(`${collections.examQuestions}/${examId}_${index + 1}`),
  );
}

export const answerKeyRef = (db, examId) =>
  db.doc(`${collections.examAnswerKeys}/${examId}`);

/**
 * The questions of [examId], or null when it does not hold its ten
 * questions. [reader] is the database or a transaction.
 */
export async function readExamQuestions(db, reader, examId) {
  const snapshots = await reader.getAll(...examQuestionRefs(db, examId));
  return examQuestionsFrom(
    examId,
    snapshots.map((snapshot) => snapshot.data()),
  );
}

/**
 * The answer key of [questions] as `question_answers` holds it now, or null
 * when the correct answer of a question is missing.
 */
export async function readCurrentAnswerKey(db, reader, questions) {
  const ids = [...new Set(questions.map((question) => question.questionId))];
  const snapshots = await reader.getAll(
    ...ids.map((id) => db.doc(`${collections.questionAnswers}/${id}`)),
  );
  return answerKeyFrom(
    questions,
    new Map(
      snapshots.map((snapshot) => [
        snapshot.id,
        snapshot.data()?.correctAnswer,
      ]),
    ),
  );
}

/** The fields of the `exam_answer_keys` document of [examId]. */
export function answerKeyDocument(examId, key, source) {
  return {
    examId,
    answers: key,
    source,
    createdAt: FieldValue.serverTimestamp(),
  };
}

/**
 * The fields of the evaluation of [examId] before its review: the theory
 * score is final, and everything the supervisor enters is still empty.
 */
export function pendingEvaluationDocument(examId, grade) {
  return {
    examId,
    supervisorId: null,
    recitationScore: null,
    theoryScore: grade.theoryScore,
    correctCount: grade.correctCount,
    finalScore: null,
    result: null,
    feedback: null,
    detailedErrors: [],
    status: 'pending',
    gradedAt: FieldValue.serverTimestamp(),
    reviewedAt: null,
    approvedAt: null,
  };
}
