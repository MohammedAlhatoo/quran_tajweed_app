// Tests of the examination functions against the Firestore emulator. Run
// from the project root:
//
//   firebase emulators:exec --only firestore --project demo-quran-exam "npm --prefix functions test"
//
// The "demo-" project ID keeps every request on the local emulator; no real
// Firebase project is read or written. Without the emulator these tests are
// skipped.
import assert from 'node:assert/strict';
import { before, beforeEach, describe, test } from 'node:test';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { snapshotAnswerKey } from '../src/answer_key.js';
import { backfillPendingEvaluations } from '../src/backfill.js';
import { SubmissionRefused, submitExam } from '../src/submit_exam.js';

const projectId = 'demo-quran-exam';
const emulator = process.env.FIRESTORE_EMULATOR_HOST;
const orders = Array.from({ length: 10 }, (_, index) => index + 1);

let db;

const user = (role, isActive = true) => ({ name: 'أحمد', role, isActive });

const exam = (studentId, status = 'in_progress') => ({
  studentId,
  courseId: 'c1',
  segmentId: 'seg1',
  status,
  mosqueId: 'm1',
  squareId: 's1',
  regionId: 'r1',
  submittedAt: null,
});

/** Answers that choose 'أ', the first [wrong] of them choosing 'ب'. */
const answers = (wrong = 0) =>
  orders.map((order) => ({
    order,
    questionId: `q${order}`,
    answer: order <= wrong ? 'ب' : 'أ',
  }));

/** Seeds an examination of [studentId] with [count] questions. */
async function seedExam(examId, studentId = 'stu1', { status, count = 10 } = {}) {
  const batch = db.batch();
  batch.set(db.doc(`exams/${examId}`), exam(studentId, status));
  for (const order of orders.slice(0, count)) {
    batch.set(db.doc(`exam_questions/${examId}_${order}`), {
      examId,
      studentId,
      questionId: `q${order}`,
      order,
      type: 'multiple_choice',
      question: `سؤال ${order}`,
      options: ['أ', 'ب', 'ج', 'د'],
    });
  }
  await batch.commit();
}

const data = async (path) => (await db.doc(path).get()).data();

const refused = (code) => (error) =>
  error instanceof SubmissionRefused && error.code === code;

describe('examination functions', { skip: !emulator }, () => {
  before(() => {
    if (getApps().length === 0) initializeApp({ projectId });
    db = getFirestore();
  });

  beforeEach(async () => {
    await fetch(
      `http://${emulator}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
      { method: 'DELETE' },
    );
    const batch = db.batch();
    batch.set(db.doc('users/stu1'), user('student'));
    batch.set(db.doc('users/stu2'), user('student'));
    batch.set(db.doc('users/stuSuspended'), user('student', false));
    batch.set(db.doc('users/sup1'), user('square_supervisor'));
    // The correct answer of every question is 'أ'.
    for (const order of orders) {
      batch.set(db.doc(`question_answers/q${order}`), { correctAnswer: 'أ' });
    }
    await batch.commit();
  });

  describe('snapshotAnswerKey', () => {
    test('copies the correct answer of the ten questions', async () => {
      await seedExam('e1');

      assert.equal(await snapshotAnswerKey(db, 'e1'), 'created');

      const key = await data('exam_answer_keys/e1');
      assert.equal(key.examId, 'e1');
      assert.equal(key.source, 'exam_created');
      assert.equal(key.answers.length, 10);
      assert.deepEqual(key.answers[4], {
        order: 5,
        questionId: 'q5',
        correctAnswer: 'أ',
      });
    });

    test('never replaces a key, whatever the answers become', async () => {
      await seedExam('e1');
      await snapshotAnswerKey(db, 'e1');
      await db.doc('question_answers/q1').set({ correctAnswer: 'ب' });

      assert.equal(await snapshotAnswerKey(db, 'e1'), 'exists');

      const key = await data('exam_answer_keys/e1');
      assert.equal(key.answers[0].correctAnswer, 'أ');
    });

    test('gives no key to an examination without ten questions', async () => {
      await seedExam('e1', 'stu1', { count: 9 });

      assert.equal(await snapshotAnswerKey(db, 'e1'), 'incomplete');

      assert.equal(await data('exam_answer_keys/e1'), undefined);
    });

    test('gives no key when a correct answer is not stored', async () => {
      await seedExam('e1');
      await db.doc('question_answers/q3').delete();

      assert.equal(await snapshotAnswerKey(db, 'e1'), 'incomplete');

      assert.equal(await data('exam_answer_keys/e1'), undefined);
    });
  });

  describe('submitExam', () => {
    beforeEach(async () => {
      await seedExam('e1');
      await snapshotAnswerKey(db, 'e1');
    });

    test('saves the answers and the theory score together', async () => {
      await submitExam(db, 'stu1', { examId: 'e1', answers: answers(3) });

      const submission = await data('submissions/e1');
      assert.equal(submission.studentId, 'stu1');
      assert.equal(submission.recordingUrl, 'exam_recordings/e1/recitation.m4a');
      assert.deepEqual(submission.answers, answers(3));
      assert.ok(submission.submittedAt);

      const evaluation = await data('evaluations/e1');
      assert.equal(evaluation.status, 'pending');
      assert.equal(evaluation.theoryScore, 14);
      assert.equal(evaluation.correctCount, 7);
      assert.equal(evaluation.recitationScore, null);
      assert.equal(evaluation.finalScore, null);
      assert.equal(evaluation.result, null);
      assert.equal(evaluation.supervisorId, null);
      assert.deepEqual(evaluation.detailedErrors, []);

      const submitted = await data('exams/e1');
      assert.equal(submitted.status, 'pending_review');
      assert.ok(submitted.submittedAt);

      const notification = await data('notifications/e1_submitted');
      assert.equal(notification.squareId, 's1');
      assert.equal(notification.userId, null);
      assert.equal(notification.type, 'exam_submitted');
      assert.equal(notification.relatedId, 'e1');
      assert.equal(notification.isRead, false);
      assert.match(notification.body, /أحمد/);
    });

    test('returns nothing, so the student does not learn the score', async () => {
      assert.equal(
        await submitExam(db, 'stu1', { examId: 'e1', answers: answers() }),
        undefined,
      );
    });

    test('grades with the key of the examination, not the current answers', async () => {
      // The answers of the bank change after the examination was created.
      for (const order of orders) {
        await db.doc(`question_answers/q${order}`).set({ correctAnswer: 'ب' });
      }

      await submitExam(db, 'stu1', { examId: 'e1', answers: answers() });

      assert.equal((await data('evaluations/e1')).theoryScore, 20);
    });

    test('the score stays when the answers change after the submission', async () => {
      await submitExam(db, 'stu1', { examId: 'e1', answers: answers(1) });
      await db.doc('question_answers/q1').set({ correctAnswer: 'ب' });
      await db.doc('question_answers/q2').delete();

      assert.equal((await data('evaluations/e1')).theoryScore, 18);
      assert.equal(
        (await data('exam_answer_keys/e1')).answers[0].correctAnswer,
        'أ',
      );
    });

    test('copies the key on submission when it was not stored yet', async () => {
      await seedExam('e2');

      await submitExam(db, 'stu1', { examId: 'e2', answers: answers(5) });

      const key = await data('exam_answer_keys/e2');
      assert.equal(key.source, 'submission');
      assert.equal(key.answers.length, 10);
      assert.equal((await data('evaluations/e2')).theoryScore, 10);
    });

    test('an examination is submitted only once', async () => {
      await submitExam(db, 'stu1', { examId: 'e1', answers: answers(10) });

      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e1', answers: answers() }),
        refused('failed-precondition'),
      );

      assert.equal((await data('evaluations/e1')).theoryScore, 0);
      assert.deepEqual((await data('submissions/e1')).answers, answers(10));
    });

    async function assertNothingSaved(examId = 'e1') {
      assert.equal(await data(`submissions/${examId}`), undefined);
      assert.equal(await data(`evaluations/${examId}`), undefined);
      assert.equal(await data(`notifications/${examId}_submitted`), undefined);
      assert.equal((await data(`exams/${examId}`)).status, 'in_progress');
    }

    test('refuses fewer than ten answers', async () => {
      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e1', answers: answers().slice(0, 9) }),
        refused('invalid-argument'),
      );
      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e1' }),
        refused('invalid-argument'),
      );
      await assertNothingSaved();
    });

    test('refuses an answer to a question the examination does not hold', async () => {
      const sent = answers();
      sent[0] = { ...sent[0], questionId: 'q99' };

      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e1', answers: sent }),
        refused('invalid-argument'),
      );
      await assertNothingSaved();
    });

    test('refuses an examination without its ten questions', async () => {
      await seedExam('e2', 'stu1', { count: 9 });

      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e2', answers: answers() }),
        refused('failed-precondition'),
      );
      await assertNothingSaved('e2');
    });

    test('refuses an examination that repeats a question', async () => {
      await seedExam('e2');
      await db.doc('exam_questions/e2_10').update({ questionId: 'q1' });
      // The answers name the questions as the examination holds them.
      const sent = answers();
      sent[9] = { ...sent[9], questionId: 'q1' };

      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e2', answers: sent }),
        refused('failed-precondition'),
      );
      await assertNothingSaved('e2');
      assert.equal(await data('exam_answer_keys/e2'), undefined);
    });

    test('refuses an examination that cannot be graded', async () => {
      await seedExam('e2');
      await db.doc('question_answers/q4').delete();

      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'e2', answers: answers() }),
        refused('failed-precondition'),
      );
      await assertNothingSaved('e2');
      assert.equal(await data('exam_answer_keys/e2'), undefined);
    });

    test('refuses the examination of another student', async () => {
      await assert.rejects(
        submitExam(db, 'stu2', { examId: 'e1', answers: answers() }),
        refused('not-found'),
      );
      await assert.rejects(
        submitExam(db, 'stu1', { examId: 'missing', answers: answers() }),
        refused('not-found'),
      );
      await assertNothingSaved();
    });

    test('refuses a suspended student, a supervisor and an unknown account', async () => {
      await seedExam('eSuspended', 'stuSuspended');
      await seedExam('eSup', 'sup1');

      await assert.rejects(
        submitExam(db, 'stuSuspended', { examId: 'eSuspended', answers: answers() }),
        refused('permission-denied'),
      );
      await assert.rejects(
        submitExam(db, 'sup1', { examId: 'eSup', answers: answers() }),
        refused('permission-denied'),
      );
      await assert.rejects(
        submitExam(db, 'ghost', { examId: 'e1', answers: answers() }),
        refused('permission-denied'),
      );
      await assertNothingSaved('eSuspended');
      await assertNothingSaved();
    });

    test('refuses a malformed examination ID', async () => {
      for (const examId of [undefined, '', 7, 'e1/../e2']) {
        await assert.rejects(
          submitExam(db, 'stu1', { examId, answers: answers() }),
          refused('invalid-argument'),
        );
      }
      await assert.rejects(submitExam(db, 'stu1', null), refused('invalid-argument'));
    });
  });

  describe('backfillPendingEvaluations', () => {
    const submission = (examId, sent) => ({
      examId,
      studentId: 'stu1',
      recordingUrl: `exam_recordings/${examId}/recitation.m4a`,
      answers: sent,
    });

    beforeEach(async () => {
      // Submitted before the theory score was saved on submission.
      await seedExam('eOld', 'stu1', { status: 'pending_review' });
      await db.doc('submissions/eOld').set(submission('eOld', answers(2)));
      // Incomplete: nine questions, and nine answers.
      await seedExam('eFewQuestions', 'stu1', { status: 'pending_review', count: 9 });
      await db
        .doc('submissions/eFewQuestions')
        .set(submission('eFewQuestions', answers().slice(0, 9)));
      await seedExam('eFewAnswers', 'stu1', { status: 'pending_review' });
      await db
        .doc('submissions/eFewAnswers')
        .set(submission('eFewAnswers', answers().slice(0, 9)));
      // Approved earlier, and one still open.
      await seedExam('eApproved', 'stu1', { status: 'approved' });
      await seedExam('eOpen', 'stu1');
    });

    test('a dry run reports and writes nothing', async () => {
      const report = await backfillPendingEvaluations(db, { apply: false });

      assert.deepEqual(report.graded, ['eOld']);
      assert.equal(await data('evaluations/eOld'), undefined);
      assert.equal(await data('exam_answer_keys/eOld'), undefined);
    });

    test('grades a complete examination and leaves the others', async () => {
      const report = await backfillPendingEvaluations(db, { apply: true });

      assert.deepEqual(report.graded, ['eOld']);
      assert.deepEqual(
        report.incomplete.map(({ examId }) => examId).sort(),
        ['eFewAnswers', 'eFewQuestions'],
      );
      const evaluation = await data('evaluations/eOld');
      assert.equal(evaluation.status, 'pending');
      assert.equal(evaluation.theoryScore, 16);
      assert.equal(evaluation.recitationScore, null);
      assert.equal((await data('exam_answer_keys/eOld')).source, 'backfill');
      assert.equal((await data('exams/eOld')).status, 'pending_review');

      for (const examId of ['eFewQuestions', 'eFewAnswers', 'eApproved', 'eOpen']) {
        assert.equal(await data(`evaluations/${examId}`), undefined, examId);
        assert.equal(await data(`exam_answer_keys/${examId}`), undefined, examId);
      }
      assert.equal((await data('exams/eFewQuestions')).status, 'pending_review');
    });

    test('running it again changes nothing', async () => {
      await backfillPendingEvaluations(db, { apply: true });
      await db.doc('question_answers/q1').set({ correctAnswer: 'ب' });

      const report = await backfillPendingEvaluations(db, { apply: true });

      assert.deepEqual(report.graded, []);
      assert.deepEqual(report.alreadyGraded, ['eOld']);
      assert.equal((await data('evaluations/eOld')).theoryScore, 16);
    });
  });
});
