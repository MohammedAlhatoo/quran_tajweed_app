// Tests of the two functions as they are deployed, on the Functions, Firestore
// and Authentication emulators: the trigger fires on a new examination, and
// the callable function is called over HTTP as the app calls it. Run from the
// project root:
//
//   firebase emulators:exec --only functions,firestore,auth --project demo-quran-exam "npm --prefix functions run test:deployed"
//
// The "demo-" project ID keeps every request on the local emulators; nothing
// is deployed. Without the three emulators these tests are skipped.
import assert from 'node:assert/strict';
import { before, describe, test } from 'node:test';

import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = 'demo-quran-exam';
const authEmulator = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const functionsEmulator = await functionsEmulatorHost();
const emulators =
  process.env.FIRESTORE_EMULATOR_HOST && authEmulator && functionsEmulator;

/** The address of the Functions emulator, asked of the emulator hub. */
async function functionsEmulatorHost() {
  const hub = process.env.FIREBASE_EMULATOR_HUB;
  if (!hub) return null;
  try {
    const running = await (await fetch(`http://${hub}/emulators`)).json();
    const functions = running.functions;
    return functions ? `${functions.host}:${functions.port}` : null;
  } catch {
    return null;
  }
}
const orders = Array.from({ length: 10 }, (_, index) => index + 1);

let db;

/** Creates an account on the Authentication emulator and signs it in. */
async function signUp(email) {
  const response = await fetch(
    `http://${authEmulator}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'secret-123', returnSecureToken: true }),
    },
  );
  const account = await response.json();
  return { uid: account.localId, token: account.idToken };
}

/** Calls `submitExam` as the app does; [token] is null when signed out. */
async function callSubmitExam(token, data) {
  const response = await fetch(
    `http://${functionsEmulator}/${projectId}/us-central1/submitExam`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ data }),
    },
  );
  return response.json();
}

async function createExam(examId, studentId) {
  const batch = db.batch();
  batch.set(db.doc(`exams/${examId}`), {
    studentId,
    courseId: 'c1',
    segmentId: 'seg1',
    status: 'in_progress',
    mosqueId: 'm1',
    squareId: 's1',
    regionId: 'r1',
    submittedAt: null,
  });
  for (const order of orders) {
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

/** Waits for the document the trigger writes. */
async function eventually(path) {
  for (let attempt = 0; attempt < 100; attempt++) {
    const snapshot = await db.doc(path).get();
    if (snapshot.exists) return snapshot.data();
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  assert.fail(`${path} was not written.`);
}

const answers = (wrong = 0) =>
  orders.map((order) => ({
    order,
    questionId: `q${order}`,
    answer: order <= wrong ? 'ب' : 'أ',
  }));

describe('deployed functions', { skip: !emulators }, () => {
  let student;

  before(async () => {
    if (getApps().length === 0) initializeApp({ projectId });
    db = getFirestore();
    student = await signUp(`student-${Date.now()}@test.dev`);
    const batch = db.batch();
    batch.set(db.doc(`users/${student.uid}`), {
      name: 'أحمد',
      role: 'student',
      isActive: true,
    });
    for (const order of orders) {
      batch.set(db.doc(`question_answers/q${order}`), { correctAnswer: 'أ' });
    }
    await batch.commit();
  });

  test('a new examination gets its answer key, and is graded with it', async () => {
    const examId = `exam-${Date.now()}`;
    await createExam(examId, student.uid);

    const key = await eventually(`exam_answer_keys/${examId}`);
    assert.equal(key.source, 'exam_created');
    assert.equal(key.answers.length, 10);

    // The bank changes after the examination was created.
    await db.doc('question_answers/q1').set({ correctAnswer: 'ب' });
    const response = await callSubmitExam(student.token, {
      examId,
      answers: answers(2),
    });
    await db.doc('question_answers/q1').set({ correctAnswer: 'أ' });

    // Nothing but an empty result goes back to the student.
    assert.deepEqual(response, { result: {} });
    const evaluation = (await db.doc(`evaluations/${examId}`).get()).data();
    assert.equal(evaluation.status, 'pending');
    assert.equal(evaluation.theoryScore, 16);
    assert.equal((await db.doc(`exams/${examId}`).get()).data().status, 'pending_review');
    assert.equal((await db.doc(`submissions/${examId}`).get()).data().studentId, student.uid);

    const again = await callSubmitExam(student.token, { examId, answers: answers() });
    assert.equal(again.error.status, 'FAILED_PRECONDITION');
    assert.equal((await db.doc(`evaluations/${examId}`).get()).data().theoryScore, 16);
  });

  test('a caller who is not signed in is refused', async () => {
    const examId = `exam-open-${Date.now()}`;
    await createExam(examId, student.uid);

    const response = await callSubmitExam(null, { examId, answers: answers() });

    assert.equal(response.error.status, 'UNAUTHENTICATED');
    assert.equal((await db.doc(`submissions/${examId}`).get()).exists, false);
  });

  test('another student is refused, with a message for the app', async () => {
    const examId = `exam-other-${Date.now()}`;
    await createExam(examId, student.uid);
    const other = await signUp(`other-${Date.now()}@test.dev`);
    await db.doc(`users/${other.uid}`).set({ name: 'x', role: 'student', isActive: true });

    const response = await callSubmitExam(other.token, { examId, answers: answers() });

    assert.equal(response.error.status, 'NOT_FOUND');
    assert.equal(response.error.message, 'هذا الاختبار غير موجود.');
    assert.equal((await db.doc(`evaluations/${examId}`).get()).exists, false);
  });
});
