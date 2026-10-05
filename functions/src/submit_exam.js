import { FieldValue } from 'firebase-admin/firestore';

import {
  answerKeyDocument,
  answerKeyRef,
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

/** A refused submission, with an Arabic message ready to show the student. */
export class SubmissionRefused extends Error {
  /** [code] is a callable function error code. */
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/** The Storage path of the recitation of [examId], as the app uploads it. */
export const recordingPath = (examId) =>
  `exam_recordings/${examId}/recitation.m4a`;

/**
 * Submits the examination [data.examId] of the student [uid] with the ten
 * answers [data.answers], each `{order, questionId, answer}`.
 *
 * In one transaction: saves the submission, grades the answers against the
 * answer key of the examination, saves the theory score in a pending
 * evaluation, moves the examination to `pending_review`, and notifies the
 * supervisor of its square. The theory score is not returned.
 *
 * Throws [SubmissionRefused] when the examination cannot be submitted.
 */
export async function submitExam(db, uid, data) {
  const examId = data?.examId;
  if (typeof examId !== 'string' || examId.length === 0 || examId.includes('/')) {
    throw new SubmissionRefused('invalid-argument', 'هذا الاختبار غير موجود.');
  }
  const examRef = db.doc(`${collections.exams}/${examId}`);
  const keyRef = answerKeyRef(db, examId);

  await db.runTransaction(async (transaction) => {
    const [user, exam, storedKey] = await transaction.getAll(
      db.doc(`${collections.users}/${uid}`),
      examRef,
      keyRef,
    );
    if (user.data()?.role !== 'student' || user.data()?.isActive !== true) {
      throw new SubmissionRefused(
        'permission-denied',
        'لا تملك صلاحية تنفيذ هذا الإجراء.',
      );
    }
    if (!exam.exists || exam.data().studentId !== uid) {
      throw new SubmissionRefused('not-found', 'هذا الاختبار غير موجود.');
    }
    if (exam.data().status !== 'in_progress') {
      throw new SubmissionRefused(
        'failed-precondition',
        'تم إرسال هذا الاختبار من قبل.',
      );
    }

    const questions = await readExamQuestions(db, transaction, examId);
    if (questions == null) {
      throw new SubmissionRefused(
        'failed-precondition',
        'أسئلة هذا الاختبار غير مكتملة، لذا لا يمكن إرساله. تواصل مع الإدارة.',
      );
    }
    const answers = submittedAnswersFrom(questions, data.answers);
    if (answers == null) {
      throw new SubmissionRefused(
        'invalid-argument',
        'أجب عن جميع الأسئلة العشرة قبل الإرسال.',
      );
    }

    // The key copied when the examination was created. One that is not
    // stored yet is copied now, and is the one kept from here on.
    let key;
    if (storedKey.exists) {
      key = storedAnswerKey(questions, storedKey.data().answers);
    } else {
      key = await readCurrentAnswerKey(db, transaction, questions);
    }
    if (key == null) {
      throw new SubmissionRefused(
        'failed-precondition',
        'تعذّر احتساب درجة الأسئلة النظرية لهذا الاختبار. تواصل مع الإدارة.',
      );
    }
    const grade = gradeTheory(key, answers);

    if (!storedKey.exists) {
      transaction.create(
        keyRef,
        answerKeyDocument(examId, key, keySources.submission),
      );
    }
    // The submission and the evaluation share the examination's ID, so an
    // examination is submitted and graded only once.
    transaction.create(db.doc(`${collections.submissions}/${examId}`), {
      examId,
      studentId: uid,
      // The Storage path, not a download link: a link would let anyone
      // holding it bypass the Storage rules.
      recordingUrl: recordingPath(examId),
      answers,
      submittedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.create(
      db.doc(`${collections.evaluations}/${examId}`),
      pendingEvaluationDocument(examId, grade),
    );
    transaction.update(examRef, {
      status: 'pending_review',
      submittedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    // The notification goes to the square the examination was started in,
    // which is the square whose supervisor reviews it.
    const squareId = exam.data().squareId;
    if (typeof squareId === 'string' && squareId.length > 0) {
      transaction.set(
        db.doc(`${collections.notifications}/${examId}_submitted`),
        {
          userId: null,
          squareId,
          title: 'اختبار جديد يحتاج مراجعة',
          body: `أرسل الطالب ${user.data().name ?? ''} اختبارًا بانتظار مراجعتك.`,
          type: 'exam_submitted',
          relatedId: examId,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        },
      );
    }
  });
}
