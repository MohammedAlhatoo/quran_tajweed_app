import {
  answerKeyDocument,
  answerKeyRef,
  keySources,
  readCurrentAnswerKey,
  readExamQuestions,
} from './exam_store.js';

const ALREADY_EXISTS = 6;

/**
 * Copies the correct answers of the ten questions of [examId] into
 * `exam_answer_keys/{examId}`, so that the examination is graded with the
 * answers as they were when it was created.
 *
 * Returns `created`, `exists` when the key was already stored, or
 * `incomplete` when the examination does not hold ten questions with a
 * stored correct answer; such an examination gets no key.
 */
export async function snapshotAnswerKey(db, examId) {
  const questions = await readExamQuestions(db, db, examId);
  if (questions == null) return 'incomplete';
  const key = await readCurrentAnswerKey(db, db, questions);
  if (key == null) return 'incomplete';
  try {
    // Never replaces a key: the first copy is the one the grading uses.
    await answerKeyRef(db, examId).create(
      answerKeyDocument(examId, key, keySources.examCreated),
    );
    return 'created';
  } catch (error) {
    if (error.code === ALREADY_EXISTS) return 'exists';
    throw error;
  }
}
