import {
  answerKeyDocument,
  answerKeyRef,
  awaitingReviewStatuses,
  collections,
  keySources,
  pendingEvaluationDocument,
  readCurrentAnswerKey,
  readExamQuestions,
} from './exam_store.js';
import {
  gradeTheory,
  storedAnswerKey,
  submittedAnswersFrom,
} from './grading.js';

/**
 * Grades the examinations that were submitted before the theory score was
 * saved on submission, so that they can still be reviewed and approved.
 *
 * Only an examination awaiting review, without an evaluation, that holds its
 * ten questions and its ten answers is graded: it gets its answer key, from
 * `question_answers` as it is now, and a pending evaluation. An incomplete
 * examination is reported and left exactly as it is; nothing grades or
 * approves it. Approved examinations are never read.
 *
 * With [apply] false nothing is written. Returns the IDs by outcome:
 * `graded`, `alreadyGraded` and `incomplete` (each with its `reason`).
 */
export async function backfillPendingEvaluations(db, { apply }) {
  const report = { graded: [], alreadyGraded: [], incomplete: [] };
  const exams = await db
    .collection(collections.exams)
    .where('status', 'in', awaitingReviewStatuses)
    .get();

  for (const exam of exams.docs) {
    const examId = exam.id;
    const reason = await db.runTransaction(async (transaction) => {
      const keyRef = answerKeyRef(db, examId);
      const evaluationRef = db.doc(`${collections.evaluations}/${examId}`);
      const [evaluation, submission, storedKey] = await transaction.getAll(
        evaluationRef,
        db.doc(`${collections.submissions}/${examId}`),
        keyRef,
      );
      if (evaluation.exists) return 'already graded';

      const questions = await readExamQuestions(db, transaction, examId);
      if (questions == null) return 'the ten questions are not stored';
      const answers = submittedAnswersFrom(
        questions,
        submission.data()?.answers,
      );
      if (answers == null) return 'the ten answers are not stored';
      const key = storedKey.exists
        ? storedAnswerKey(questions, storedKey.data().answers)
        : await readCurrentAnswerKey(db, transaction, questions);
      if (key == null) return 'a correct answer is not stored';

      if (apply) {
        if (!storedKey.exists) {
          transaction.create(
            keyRef,
            answerKeyDocument(examId, key, keySources.backfill),
          );
        }
        transaction.create(
          evaluationRef,
          pendingEvaluationDocument(examId, gradeTheory(key, answers)),
        );
      }
      return null;
    });

    if (reason == null) {
      report.graded.push(examId);
    } else if (reason === 'already graded') {
      report.alreadyGraded.push(examId);
    } else {
      report.incomplete.push({ examId, reason });
    }
  }
  return report;
}
