// The trusted backend of the examination. Deployed with the Firebase CLI;
// nothing in the app or in the tests deploys it.
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { logger, setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { snapshotAnswerKey } from './src/answer_key.js';
import { SubmissionRefused, submitExam as submit } from './src/submit_exam.js';

initializeApp();
// The app calls `submitExam` in this region.
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

/**
 * Copies the answer key of an examination when it is created. Retried until
 * it succeeds; a key that is already stored is left as it is.
 */
export const snapshotExamAnswerKey = onDocumentCreated(
  { document: 'exams/{examId}', retry: true },
  async (event) => {
    const examId = event.params.examId;
    const outcome = await snapshotAnswerKey(getFirestore(), examId);
    if (outcome === 'incomplete') {
      logger.warn('No answer key: the examination is incomplete.', { examId });
    }
  },
);

/**
 * Submits the caller's examination: `{examId, answers}`. See
 * `src/submit_exam.js`.
 */
export const submitExam = onCall(async (request) => {
  if (request.auth == null) {
    throw new HttpsError('unauthenticated', 'سجّل الدخول ثم حاول مرة أخرى.');
  }
  try {
    await submit(getFirestore(), request.auth.uid, request.data);
  } catch (error) {
    if (error instanceof SubmissionRefused) {
      throw new HttpsError(error.code, error.message);
    }
    logger.error('submitExam failed.', error);
    throw new HttpsError('internal', 'حدث خطأ غير متوقع. حاول مرة أخرى.');
  }
  return {};
});
