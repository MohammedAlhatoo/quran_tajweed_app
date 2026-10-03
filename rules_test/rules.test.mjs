// Tests of firestore.rules and storage.rules against the Firebase Emulator
// Suite. Run from the project root:
//
//   firebase emulators:exec --only firestore,storage --project demo-quran-exam "npm --prefix rules_test test"
//
// The "demo-" project ID keeps every request on the local emulators; no real
// Firebase project is read or written.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  setLogLevel,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

const rulesFile = (name) =>
  readFileSync(fileURLToPath(new URL(`../${name}`, import.meta.url)), 'utf8');

const seededAt = new Date('2026-01-01T00:00:00Z');
const now = serverTimestamp;

let env;

// ---------------------------------------------------------------------------
// Seed data
//
//   r1 ── s1  ── m1 (active), m3 (inactive)    stu1, stu1x, stuSuspended
//      └─ s1b                                   (no mosque)
//   r2 ── s2  ── m2 (active)                    stu2
// ---------------------------------------------------------------------------

function account(uid, role, scope = {}) {
  return {
    uid,
    name: uid,
    email: `${uid}@test.dev`,
    phone: '0590000000',
    role,
    regionId: scope.regionId ?? null,
    squareId: scope.squareId ?? null,
    mosqueId: scope.mosqueId ?? null,
    isActive: scope.isActive ?? true,
    createdAt: seededAt,
    updatedAt: seededAt,
  };
}

const inS1 = { regionId: 'r1', squareId: 's1', mosqueId: 'm1' };
const inS2 = { regionId: 'r2', squareId: 's2', mosqueId: 'm2' };

function exam(studentId, scope, status) {
  return {
    studentId,
    courseId: 'c1',
    segmentId: 'seg1',
    status,
    mosqueId: scope.mosqueId,
    squareId: scope.squareId,
    regionId: scope.regionId,
    startedAt: seededAt,
    submittedAt: status == 'in_progress' ? null : seededAt,
    reviewedAt: status == 'approved' ? seededAt : null,
    approvedAt: status == 'approved' ? seededAt : null,
    createdAt: seededAt,
    updatedAt: seededAt,
  };
}

function answers() {
  return Array.from({ length: 10 }, (_, i) => ({
    order: i + 1,
    questionId: `q${i + 1}`,
    answer: 'أ',
  }));
}

function submission(examId, studentId) {
  return {
    examId,
    studentId,
    recordingUrl: `exam_recordings/${examId}/recitation.m4a`,
    answers: answers(),
    submittedAt: seededAt,
    createdAt: seededAt,
  };
}

function detailedError(id, change = {}) {
  return {
    id,
    ruleId: 'rule1',
    ruleName: 'الإخفاء',
    ayahNumber: 3,
    word: 'أنتم',
    description: 'لم تُخفَ النون',
    createdAt: seededAt,
    ...change,
  };
}

const detailedErrors = (count) =>
  Array.from({ length: count }, (_, i) => detailedError(`error-${i + 1}`));

function evaluation(examId, supervisorId) {
  return {
    examId,
    supervisorId,
    recitationScore: 70,
    theoryScore: 18,
    finalScore: 88,
    result: 'passed',
    feedback: 'راجع أحكام النون الساكنة',
    detailedErrors: detailedErrors(1),
    status: 'approved',
    reviewedAt: seededAt,
    approvedAt: seededAt,
  };
}

function certificate(examId, studentId) {
  return {
    studentId,
    examId,
    courseId: 'c1',
    certificateNumber: `CERT-${examId}`,
    finalScore: 88,
    issuedAt: seededAt,
    fileUrl: null,
  };
}

function notification(target) {
  return {
    userId: target.userId ?? null,
    squareId: target.squareId ?? null,
    title: 'عنوان',
    body: 'نص',
    type: target.userId ? 'exam_approved' : 'exam_submitted',
    relatedId: 'e1',
    isRead: false,
    createdAt: seededAt,
  };
}

function examQuestion(examId, studentId, order) {
  return {
    examId,
    studentId,
    questionId: `q${order}`,
    order,
    type: 'multiple_choice',
    question: 'سؤال',
    options: ['أ', 'ب', 'ج', 'د'],
  };
}

const seed = {
  'regions/r1': { name: 'R1', description: '', officerId: 'officer1', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'regions/r2': { name: 'R2', description: '', officerId: 'officer2', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'squares/s1': { name: 'S1', regionId: 'r1', supervisorId: 'sup1', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'squares/s1b': { name: 'S1b', regionId: 'r1', supervisorId: 'sup1b', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'squares/s2': { name: 'S2', regionId: 'r2', supervisorId: 'sup2', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'mosques/m1': { name: 'M1', address: '', squareId: 's1', regionId: 'r1', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'mosques/m2': { name: 'M2', address: '', squareId: 's2', regionId: 'r2', isActive: true, createdAt: seededAt, updatedAt: seededAt },
  'mosques/m3': { name: 'M3', address: '', squareId: 's1', regionId: 'r1', isActive: false, createdAt: seededAt, updatedAt: seededAt },

  'users/admin': account('admin', 'general_admin'),
  'users/officer1': account('officer1', 'region_officer', { regionId: 'r1' }),
  'users/officer2': account('officer2', 'region_officer', { regionId: 'r2' }),
  'users/sup1': account('sup1', 'square_supervisor', { regionId: 'r1', squareId: 's1' }),
  'users/sup1b': account('sup1b', 'square_supervisor', { regionId: 'r1', squareId: 's1b' }),
  'users/sup2': account('sup2', 'square_supervisor', { regionId: 'r2', squareId: 's2' }),
  'users/supNoSquare': account('supNoSquare', 'square_supervisor', { regionId: 'r1' }),
  'users/supInactive': account('supInactive', 'square_supervisor', { regionId: 'r1', squareId: 's1', isActive: false }),
  'users/stu1': account('stu1', 'student', inS1),
  'users/stu1x': account('stu1x', 'student', inS1),
  'users/stuSuspended': account('stuSuspended', 'student', { ...inS1, isActive: false }),
  'users/stu2': account('stu2', 'student', inS2),

  'courses/c1': { name: 'C1', isActive: true },
  'exam_segments/seg1': { isActive: true, courseIds: ['c1'] },
  'question_bank/q1': { question: 'سؤال', options: ['أ', 'ب'] },
  'question_answers/q1': { correctAnswer: 'أ' },

  // e1: stu1, awaiting review.  eOpen: stu1, in progress.
  // eA: stu1, approved.  e2 / eB: stu2 in the other square and region.
  'exams/e1': exam('stu1', inS1, 'pending_review'),
  'exams/eOpen': exam('stu1', inS1, 'in_progress'),
  'exams/eA': exam('stu1', inS1, 'approved'),
  'exams/eSuspended': exam('stuSuspended', inS1, 'in_progress'),
  'exams/e2': exam('stu2', inS2, 'pending_review'),
  'exams/eB': exam('stu2', inS2, 'approved'),
  'submissions/e1': submission('e1', 'stu1'),
  'submissions/e2': submission('e2', 'stu2'),
  'exam_questions/e1_1': examQuestion('e1', 'stu1', 1),
  'exam_questions/e2_1': examQuestion('e2', 'stu2', 1),
  'evaluations/eA': evaluation('eA', 'sup1'),
  'evaluations/eB': evaluation('eB', 'sup2'),
  'certificates/eA': certificate('eA', 'stu1'),
  'certificates/eB': certificate('eB', 'stu2'),
  'notifications/n_stu1': notification({ userId: 'stu1' }),
  'notifications/n_stu2': notification({ userId: 'stu2' }),
  'notifications/n_s1': notification({ squareId: 's1' }),
  'notifications/n_s2': notification({ squareId: 's2' }),
  'staff_invites/invited': {
    name: 'invited', email: 'invited@test.dev', phone: '0590000000',
    role: 'square_supervisor', regionId: 'r1', squareId: 's1b',
    createdBy: 'officer1', createdAt: seededAt,
  },
};

async function seedFirestore(extra = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const entries = Object.entries({ ...seed, ...extra });
    for (let i = 0; i < entries.length; i += 400) {
      const batch = writeBatch(db);
      for (const [path, data] of entries.slice(i, i + 400)) {
        batch.set(doc(db, path), data);
      }
      await batch.commit();
    }
  });
}

const recordingPath = (examId) => `exam_recordings/${examId}/recitation.m4a`;
const audio = () => new Uint8Array([1, 2, 3, 4]);
const m4a = { contentType: 'audio/mp4' };

// ---------------------------------------------------------------------------

const as = (uid) =>
  env.authenticatedContext(uid, { email: `${uid}@test.dev` });
const db = (uid) => as(uid).firestore();
const storage = (uid) => as(uid).storage();
const anonymousDb = () => env.unauthenticatedContext().firestore();

const read = (firestore, path) => getDoc(doc(firestore, path));
const list = (firestore, name, ...filters) =>
  getDocs(query(collection(firestore, name), ...filters));
const listen = (uid, examId) => getBytes(ref(storage(uid), recordingPath(examId)));

before(async () => {
  setLogLevel('error');
  env = await initializeTestEnvironment({
    projectId: 'demo-quran-exam',
    firestore: { rules: rulesFile('firestore.rules') },
    storage: { rules: rulesFile('storage.rules') },
  });
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (context) => {
    for (const examId of ['e1', 'eOpen', 'e2']) {
      await uploadBytes(ref(context.storage(), recordingPath(examId)), audio(), m4a);
    }
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seedFirestore();
});

after(async () => {
  await env.cleanup();
});

// ===========================================================================
// Denied
// ===========================================================================

describe('denied: student', () => {
  test('reads another student of the same square', async () => {
    await assertFails(read(db('stu1'), 'users/stu1x'));
  });

  test('reads a student of another square', async () => {
    await assertFails(read(db('stu1'), 'users/stu2'));
  });

  test('lists users', async () => {
    await assertFails(list(db('stu1'), 'users'));
    await assertFails(list(db('stu1'), 'users', where('squareId', '==', 's1')));
  });

  test('reads question_answers', async () => {
    await assertFails(read(db('stu1'), 'question_answers/q1'));
    await assertFails(list(db('stu1'), 'question_answers'));
  });

  test('changes own role', async () => {
    for (const role of ['general_admin', 'region_officer', 'square_supervisor']) {
      await assertFails(
        updateDoc(doc(db('stu1'), 'users/stu1'), { role, updatedAt: now() }),
      );
    }
  });

  test('registers with an administrative role', async () => {
    const profile = {
      ...account('newcomer', 'student', inS1),
      createdAt: now(),
      updatedAt: now(),
    };
    for (const role of ['general_admin', 'region_officer', 'square_supervisor']) {
      await assertFails(
        setDoc(doc(db('newcomer'), 'users/newcomer'), { ...profile, role }),
      );
    }
  });

  test('changes own mosqueId, squareId or regionId', async () => {
    const own = doc(db('stu1'), 'users/stu1');
    await assertFails(updateDoc(own, { mosqueId: 'm2', updatedAt: now() }));
    await assertFails(updateDoc(own, { squareId: 's2', updatedAt: now() }));
    await assertFails(updateDoc(own, { regionId: 'r2', updatedAt: now() }));
    await assertFails(
      updateDoc(own, { mosqueId: 'm2', squareId: 's2', regionId: 'r2', updatedAt: now() }),
    );
  });

  test('changes own name, or reactivates own account', async () => {
    await assertFails(
      updateDoc(doc(db('stu1'), 'users/stu1'), { name: 'x', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('stuSuspended'), 'users/stuSuspended'), {
        isActive: true,
        updatedAt: now(),
      }),
    );
  });

  test('registers into a square or region other than the mosque\'s', async () => {
    const profile = {
      ...account('newcomer', 'student', { ...inS1, squareId: 's2' }),
      createdAt: now(),
      updatedAt: now(),
    };
    await assertFails(setDoc(doc(db('newcomer'), 'users/newcomer'), profile));
    await assertFails(
      setDoc(doc(db('newcomer'), 'users/newcomer'), { ...profile, ...inS1, mosqueId: 'm3' }),
    );
  });

  test('approves own examination or adds a field to it', async () => {
    const own = doc(db('stu1'), 'exams/e1');
    await assertFails(updateDoc(own, { status: 'approved', updatedAt: now() }));
    await assertFails(updateDoc(own, { finalScore: 100 }));
    await assertFails(updateDoc(doc(db('stu1'), 'exams/eOpen'), { squareId: 's2' }));
  });

  test('submits an examination without its submission', async () => {
    await assertFails(
      updateDoc(doc(db('stu1'), 'exams/eOpen'), {
        status: 'pending_review',
        submittedAt: now(),
        updatedAt: now(),
      }),
    );
  });

  test('writes an evaluation or a certificate', async () => {
    await assertFails(
      setDoc(doc(db('stu1'), 'evaluations/e1'), {
        ...evaluation('e1', 'stu1'),
        reviewedAt: now(),
        approvedAt: now(),
      }),
    );
    await assertFails(
      setDoc(doc(db('stu1'), 'certificates/e1'), {
        ...certificate('e1', 'stu1'),
        issuedAt: now(),
      }),
    );
    await assertFails(updateDoc(doc(db('stu1'), 'evaluations/eA'), { finalScore: 100 }));
    await assertFails(updateDoc(doc(db('stu1'), 'certificates/eA'), { finalScore: 100 }));
  });

  test('changes the notes, the errors or the result of an evaluation', async () => {
    const own = doc(db('stu1'), 'evaluations/eA');
    await assertFails(updateDoc(own, { feedback: 'ممتاز' }));
    await assertFails(updateDoc(own, { feedback: null }));
    await assertFails(updateDoc(own, { detailedErrors: [] }));
    await assertFails(
      updateDoc(own, { detailedErrors: [detailedError('error-1', { description: '' })] }),
    );
    await assertFails(updateDoc(own, { recitationScore: 80 }));
    await assertFails(updateDoc(own, { result: 'passed', status: 'approved' }));
    await assertFails(deleteDoc(own));
  });

  test('starts an examination in another square', async () => {
    await assertFails(
      setDoc(doc(db('stu1'), 'exams/new'), {
        ...exam('stu1', { ...inS1, squareId: 's2' }, 'in_progress'),
        startedAt: now(),
        createdAt: now(),
        updatedAt: now(),
      }),
    );
  });

  test('starts an examination for another student', async () => {
    await assertFails(
      setDoc(doc(db('stu1'), 'exams/new'), {
        ...exam('stu1x', inS1, 'in_progress'),
        startedAt: now(),
        createdAt: now(),
        updatedAt: now(),
      }),
    );
  });

  test('starts an examination while suspended', async () => {
    await assertFails(
      setDoc(doc(db('stuSuspended'), 'exams/new'), {
        ...exam('stuSuspended', inS1, 'in_progress'),
        startedAt: now(),
        createdAt: now(),
        updatedAt: now(),
      }),
    );
  });

  test('changes a submission, or content collections', async () => {
    await assertFails(updateDoc(doc(db('stu1'), 'submissions/e1'), { answers: [] }));
    await assertFails(deleteDoc(doc(db('stu1'), 'submissions/e1')));
    await assertFails(setDoc(doc(db('stu1'), 'question_bank/q9'), { question: 'x' }));
    await assertFails(setDoc(doc(db('stu1'), 'courses/c9'), { name: 'x' }));
    await assertFails(setDoc(doc(db('stu1'), 'question_answers/q1'), { correctAnswer: 'ب' }));
    await assertFails(updateDoc(doc(db('stu1'), 'exam_questions/e1_1'), { question: 'x' }));
  });

  test('reads the examination of another student', async () => {
    await assertFails(read(db('stu1'), 'exams/e2'));
    await assertFails(read(db('stu1x'), 'exams/e1'));
    await assertFails(list(db('stu1'), 'exams', where('squareId', '==', 's1')));
    await assertFails(list(db('stu1'), 'exams', where('studentId', '==', 'stu2')));
    await assertFails(list(db('stu1'), 'exams'));
  });

  test('reads the submission, questions or evaluation of another student', async () => {
    await assertFails(read(db('stu1'), 'submissions/e2'));
    await assertFails(read(db('stu1x'), 'submissions/e1'));
    await assertFails(read(db('stu1'), 'exam_questions/e2_1'));
    await assertFails(read(db('stu1'), 'evaluations/eB'));
    await assertFails(read(db('stu1x'), 'evaluations/eA'));
  });

  test('submits or updates the examination of another student', async () => {
    await assertFails(
      updateDoc(doc(db('stu1x'), 'exams/eOpen'), {
        status: 'pending_review',
        submittedAt: now(),
        updatedAt: now(),
      }),
    );
  });
});

describe('denied: supervisor without a square', () => {
  test('reads examinations', async () => {
    await assertFails(read(db('supNoSquare'), 'exams/e1'));
    await assertFails(list(db('supNoSquare'), 'exams', where('squareId', '==', 's1')));
    await assertFails(list(db('supNoSquare'), 'exams', where('regionId', '==', 'r1')));
  });

  test('reads students, squares, submissions, answers, notifications', async () => {
    await assertFails(read(db('supNoSquare'), 'users/stu1'));
    await assertFails(
      list(db('supNoSquare'), 'users', where('role', '==', 'student'), where('squareId', '==', 's1')),
    );
    await assertFails(read(db('supNoSquare'), 'squares/s1'));
    await assertFails(read(db('supNoSquare'), 'submissions/e1'));
    await assertFails(read(db('supNoSquare'), 'question_answers/q1'));
    await assertFails(read(db('supNoSquare'), 'evaluations/eA'));
    await assertFails(read(db('supNoSquare'), 'certificates/eA'));
    await assertFails(read(db('supNoSquare'), 'notifications/n_s1'));
    await assertFails(
      list(db('supNoSquare'), 'notifications', where('squareId', '==', null)),
    );
  });

  test('listens to a recording', async () => {
    await assertFails(listen('supNoSquare', 'e1'));
  });
});

describe('denied: suspended supervisor', () => {
  test('reads the data of the square', async () => {
    await assertFails(read(db('supInactive'), 'exams/e1'));
    await assertFails(read(db('supInactive'), 'question_answers/q1'));
    await assertFails(read(db('supInactive'), 'users/stu1'));
    await assertFails(listen('supInactive', 'e1'));
  });
});

describe('denied: supervisor outside the square', () => {
  test('reads another square (same region and other region)', async () => {
    await assertFails(read(db('sup1'), 'squares/s1b'));
    await assertFails(read(db('sup1'), 'squares/s2'));
    await assertFails(read(db('sup1b'), 'exams/e1'));
    await assertFails(read(db('sup1'), 'exams/e2'));
    await assertFails(list(db('sup1'), 'exams', where('squareId', '==', 's2')));
    await assertFails(list(db('sup1'), 'exams'));
    await assertFails(read(db('sup1'), 'users/stu2'));
    await assertFails(
      list(db('sup1'), 'users', where('role', '==', 'student'), where('squareId', '==', 's2')),
    );
    await assertFails(read(db('sup1'), 'submissions/e2'));
    await assertFails(read(db('sup1'), 'exam_questions/e2_1'));
    await assertFails(read(db('sup1'), 'evaluations/eB'));
    await assertFails(read(db('sup1'), 'certificates/eB'));
  });

  test('reads a region, its own or another', async () => {
    await assertFails(read(db('sup1'), 'regions/r2'));
    await assertFails(read(db('sup1'), 'regions/r1'));
    await assertFails(list(db('sup1'), 'regions'));
    await assertFails(list(db('sup1'), 'exams', where('regionId', '==', 'r2')));
    await assertFails(list(db('sup1'), 'exams', where('regionId', '==', 'r1')));
    await assertFails(list(db('sup1'), 'users', where('regionId', '==', 'r1')));
    await assertFails(list(db('sup1'), 'squares', where('regionId', '==', 'r1')));
  });

  test('reads staff accounts', async () => {
    await assertFails(read(db('sup1'), 'users/officer1'));
    await assertFails(read(db('sup1'), 'users/sup1b'));
    await assertFails(read(db('sup1'), 'users/admin'));
  });

  test('approves an examination of another square', async () => {
    const firestore = db('sup1');
    const batch = writeBatch(firestore);
    batch.update(doc(firestore, 'exams/e2'), {
      status: 'approved', reviewedAt: now(), approvedAt: now(), updatedAt: now(),
    });
    batch.set(doc(firestore, 'evaluations/e2'), {
      ...evaluation('e2', 'sup1'), reviewedAt: now(), approvedAt: now(),
    });
    await assertFails(batch.commit());
  });

  test('creates, renames or moves a mosque', async () => {
    await assertFails(
      setDoc(doc(db('sup1'), 'mosques/new'), {
        name: 'New', address: '', squareId: 's1', regionId: 'r1', isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('sup1'), 'mosques/m1'), { squareId: 's1b', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('sup1'), 'mosques/m1'), { name: 'x', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('sup1'), 'mosques/m1'), { isActive: false, updatedAt: now() }),
    );
  });

  test('changes a square, a student or an invitation', async () => {
    await assertFails(updateDoc(doc(db('sup1'), 'squares/s1'), { name: 'x', updatedAt: now() }));
    await assertFails(
      updateDoc(doc(db('sup1'), 'users/stu1'), { isActive: false, updatedAt: now() }),
    );
    await assertFails(
      setDoc(doc(db('sup1'), 'staff_invites/someone'), {
        ...seed['staff_invites/invited'], squareId: 's1', createdBy: 'sup1', createdAt: now(),
      }),
    );
  });

  test('lists question_answers', async () => {
    await assertFails(list(db('sup1'), 'question_answers'));
  });
});

describe('denied: region officer outside the region', () => {
  test('reads another region', async () => {
    await assertFails(read(db('officer1'), 'regions/r2'));
    await assertFails(list(db('officer1'), 'regions'));
    await assertFails(read(db('officer1'), 'squares/s2'));
    await assertFails(list(db('officer1'), 'squares', where('regionId', '==', 'r2')));
    await assertFails(list(db('officer1'), 'squares'));
    await assertFails(read(db('officer1'), 'exams/e2'));
    await assertFails(list(db('officer1'), 'exams', where('regionId', '==', 'r2')));
    await assertFails(read(db('officer1'), 'users/stu2'));
    await assertFails(read(db('officer1'), 'users/sup2'));
    await assertFails(list(db('officer1'), 'users', where('regionId', '==', 'r2')));
    await assertFails(list(db('officer1'), 'users'));
    await assertFails(read(db('officer1'), 'evaluations/eB'));
    await assertFails(read(db('officer1'), 'certificates/eB'));
    await assertFails(read(db('officer1'), 'users/admin'));
  });

  test('creates or changes a square of another region', async () => {
    await assertFails(
      setDoc(doc(db('officer1'), 'squares/new'), {
        name: 'New', regionId: 'r2', supervisorId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'squares/s2'), { name: 'x', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'squares/s2'), { isActive: false, updatedAt: now() }),
    );
  });

  test('moves a square of the region to another region', async () => {
    await assertFails(
      updateDoc(doc(db('officer1'), 'squares/s1'), { regionId: 'r2', updatedAt: now() }),
    );
  });

  test('creates a mosque in another region, or moves one out of the region', async () => {
    await assertFails(
      setDoc(doc(db('officer1'), 'mosques/new'), {
        name: 'New', address: '', squareId: 's2', regionId: 'r2', isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    // A square of another region under the officer's own regionId.
    await assertFails(
      setDoc(doc(db('officer1'), 'mosques/new'), {
        name: 'New', address: '', squareId: 's2', regionId: 'r1', isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'mosques/m1'), {
        squareId: 's2', regionId: 'r2', updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'mosques/m1'), { squareId: 's2', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'mosques/m2'), {
        squareId: 's1', regionId: 'r1', updatedAt: now(),
      }),
    );
  });

  test('manages the accounts of another region', async () => {
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/sup2'), { isActive: false, updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/sup2'), {
        regionId: 'r1', squareId: 's1', updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/sup1'), {
        regionId: 'r2', squareId: 's2', updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/stu2'), { isActive: false, updatedAt: now() }),
    );
  });

  test('manages regions, officers or the General Admin', async () => {
    await assertFails(
      setDoc(doc(db('officer1'), 'regions/new'), {
        name: 'New', description: '', officerId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'regions/r1'), { name: 'x', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/officer2'), { isActive: false, updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/admin'), { isActive: false, updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/officer1'), { regionId: 'r2', updatedAt: now() }),
    );
  });

  test('invites staff outside the region, or an officer', async () => {
    const invite = { ...seed['staff_invites/invited'], createdBy: 'officer1', createdAt: now() };
    await assertFails(
      setDoc(doc(db('officer1'), 'staff_invites/x'), { ...invite, regionId: 'r2', squareId: 's2' }),
    );
    await assertFails(
      setDoc(doc(db('officer1'), 'staff_invites/x'), { ...invite, squareId: 's2' }),
    );
    await assertFails(
      setDoc(doc(db('officer1'), 'staff_invites/x'), {
        ...invite, role: 'region_officer', squareId: null,
      }),
    );
    await assertFails(
      setDoc(doc(db('officer1'), 'staff_invites/x'), {
        ...invite, role: 'general_admin', squareId: null,
      }),
    );
  });
});

describe('denied: ordinary users on administrative data', () => {
  test('student reads regions, squares, staff and invitations', async () => {
    await assertFails(read(db('stu1'), 'regions/r1'));
    await assertFails(list(db('stu1'), 'regions'));
    await assertFails(read(db('stu1'), 'squares/s1'));
    await assertFails(list(db('stu1'), 'squares'));
    await assertFails(read(db('stu1'), 'users/admin'));
    await assertFails(read(db('stu1'), 'users/sup1'));
    await assertFails(read(db('stu1'), 'staff_invites/invited'));
    await assertFails(read(db('stu1'), 'mosques/m3'));
    await assertFails(list(db('stu1'), 'mosques'));
  });

  test('student writes regions, squares, mosques and invitations', async () => {
    await assertFails(
      setDoc(doc(db('stu1'), 'regions/new'), {
        name: 'New', description: '', officerId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertFails(updateDoc(doc(db('stu1'), 'squares/s1'), { supervisorId: 'stu1', updatedAt: now() }));
    await assertFails(updateDoc(doc(db('stu1'), 'mosques/m1'), { name: 'x', updatedAt: now() }));
    await assertFails(
      setDoc(doc(db('stu1'), 'staff_invites/stu1x'), {
        ...seed['staff_invites/invited'], createdBy: 'stu1', createdAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('stu1'), 'users/stu1x'), { isActive: false, updatedAt: now() }),
    );
  });

  test('signed-out visitor reads anything but active mosques', async () => {
    const firestore = anonymousDb();
    await assertFails(read(firestore, 'users/stu1'));
    await assertFails(read(firestore, 'regions/r1'));
    await assertFails(read(firestore, 'squares/s1'));
    await assertFails(read(firestore, 'exams/e1'));
    await assertFails(read(firestore, 'courses/c1'));
    await assertFails(read(firestore, 'question_answers/q1'));
    await assertFails(read(firestore, 'mosques/m3'));
    await assertFails(list(firestore, 'mosques'));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), recordingPath('e1'))));
  });

  test('account without a users document reads nothing', async () => {
    await assertFails(read(db('ghost'), 'exams/e1'));
    await assertFails(read(db('ghost'), 'regions/r1'));
    await assertFails(read(db('ghost'), 'question_answers/q1'));
    await assertFails(list(db('ghost'), 'users'));
  });

  test('uninvited account creates an administrative profile', async () => {
    await assertFails(
      setDoc(doc(db('ghost'), 'users/ghost'), {
        ...account('ghost', 'square_supervisor', { regionId: 'r1', squareId: 's1' }),
        createdAt: now(), updatedAt: now(),
      }),
    );
  });

  test('invited account takes a wider role or scope than its invitation', async () => {
    const profile = {
      ...account('invited', 'square_supervisor', { regionId: 'r1', squareId: 's1b' }),
      createdAt: now(), updatedAt: now(),
    };
    const own = doc(db('invited'), 'users/invited');
    await assertFails(setDoc(own, { ...profile, role: 'region_officer' }));
    await assertFails(setDoc(own, { ...profile, role: 'general_admin' }));
    await assertFails(setDoc(own, { ...profile, squareId: 's1' }));
    await assertFails(setDoc(own, { ...profile, regionId: 'r2', squareId: 's2' }));
  });

  test('General Admin account is never changed from the application', async () => {
    await assertFails(
      updateDoc(doc(db('admin'), 'users/admin'), { name: 'x', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('admin'), 'users/stu1'), { role: 'general_admin', updatedAt: now() }),
    );
    await assertFails(deleteDoc(doc(db('admin'), 'users/stu1')));
    await assertFails(deleteDoc(doc(db('admin'), 'regions/r1')));
  });
});

describe('denied: exam_recordings', () => {
  test('supervisor of another square', async () => {
    await assertFails(listen('sup1', 'e2'));
    await assertFails(listen('sup1b', 'e1'));
    await assertFails(listen('sup2', 'e1'));
  });

  test('officer of another region', async () => {
    await assertFails(listen('officer2', 'e1'));
    await assertFails(listen('officer1', 'e2'));
  });

  test('another student', async () => {
    await assertFails(listen('stu1x', 'e1'));
    await assertFails(listen('stu2', 'e1'));
  });

  test('staff before the examination is submitted', async () => {
    await assertFails(listen('sup1', 'eOpen'));
    await assertFails(listen('officer1', 'eOpen'));
    await assertFails(listen('admin', 'eOpen'));
  });

  test('student uploads for another student or after submission', async () => {
    await assertFails(uploadBytes(ref(storage('stu1'), recordingPath('e2')), audio(), m4a));
    await assertFails(uploadBytes(ref(storage('stu1x'), recordingPath('eOpen')), audio(), m4a));
    await assertFails(uploadBytes(ref(storage('stu1'), recordingPath('e1')), audio(), m4a));
  });

  test('wrong content type, empty file, other path, suspended student', async () => {
    await assertFails(
      uploadBytes(ref(storage('stu1'), recordingPath('eOpen')), audio(), { contentType: 'text/plain' }),
    );
    await assertFails(
      uploadBytes(ref(storage('stu1'), recordingPath('eOpen')), new Uint8Array(), m4a),
    );
    await assertFails(
      uploadBytes(ref(storage('stu1'), 'exam_recordings/eOpen/other.m4a'), audio(), m4a),
    );
    await assertFails(
      uploadBytes(ref(storage('stuSuspended'), recordingPath('eSuspended')), audio(), m4a),
    );
  });

  test('staff upload, and anyone deletes', async () => {
    await assertFails(uploadBytes(ref(storage('sup1'), recordingPath('eOpen')), audio(), m4a));
    await assertFails(uploadBytes(ref(storage('admin'), recordingPath('eOpen')), audio(), m4a));
    await assertFails(deleteObject(ref(storage('stu1'), recordingPath('eOpen'))));
    await assertFails(deleteObject(ref(storage('admin'), recordingPath('e1'))));
  });
});

describe('denied: certificates and notifications of someone else', () => {
  test('student reads the certificate of another student', async () => {
    await assertFails(read(db('stu1'), 'certificates/eB'));
    await assertFails(read(db('stu1x'), 'certificates/eA'));
    await assertFails(list(db('stu1'), 'certificates', where('studentId', '==', 'stu2')));
    await assertFails(list(db('stu1'), 'certificates'));
  });

  test('student reads or marks the notification of another user', async () => {
    await assertFails(read(db('stu1'), 'notifications/n_stu2'));
    await assertFails(list(db('stu1'), 'notifications', where('userId', '==', 'stu2')));
    await assertFails(list(db('stu1'), 'notifications'));
    await assertFails(updateDoc(doc(db('stu1'), 'notifications/n_stu2'), { isRead: true }));
    await assertFails(read(db('stu1'), 'notifications/n_s1'));
  });

  test('supervisor reads the notification of another square or of a student', async () => {
    await assertFails(read(db('sup2'), 'notifications/n_s1'));
    await assertFails(list(db('sup1'), 'notifications', where('squareId', '==', 's2')));
    await assertFails(read(db('sup1'), 'notifications/n_stu1'));
  });

  test('notification owner changes anything but isRead', async () => {
    await assertFails(updateDoc(doc(db('stu1'), 'notifications/n_stu1'), { title: 'x' }));
    await assertFails(deleteDoc(doc(db('stu1'), 'notifications/n_stu1')));
  });

  test('student forges a notification', async () => {
    await assertFails(
      setDoc(doc(db('stu1'), 'notifications/e1_result'), {
        ...notification({ userId: 'stu1' }), createdAt: now(),
      }),
    );
    await assertFails(
      setDoc(doc(db('stu1'), 'notifications/eOpen_submitted'), {
        ...notification({ squareId: 's1' }), relatedId: 'eOpen', createdAt: now(),
      }),
    );
  });
});

// ===========================================================================
// Allowed
// ===========================================================================

describe('allowed: student', () => {
  test('reads own account', async () => {
    const snapshot = await assertSucceeds(read(db('stu1'), 'users/stu1'));
    assert.equal(snapshot.data().role, 'student');
  });

  test('reads own examinations', async () => {
    await assertSucceeds(read(db('stu1'), 'exams/e1'));
    const own = await assertSucceeds(
      list(db('stu1'), 'exams', where('studentId', '==', 'stu1')),
    );
    assert.equal(own.size, 3);
  });

  test('reads own submission, questions, evaluation, certificate', async () => {
    await assertSucceeds(read(db('stu1'), 'submissions/e1'));
    await assertSucceeds(list(db('stu1'), 'submissions', where('studentId', '==', 'stu1')));
    await assertSucceeds(
      list(db('stu1'), 'exam_questions', where('studentId', '==', 'stu1'), where('examId', '==', 'e1')),
    );
    await assertSucceeds(read(db('stu1'), 'evaluations/eA'));
    await assertSucceeds(read(db('stu1'), 'certificates/eA'));
    await assertSucceeds(list(db('stu1'), 'certificates', where('studentId', '==', 'stu1')));
  });

  test('reads and marks own notifications', async () => {
    await assertSucceeds(read(db('stu1'), 'notifications/n_stu1'));
    await assertSucceeds(list(db('stu1'), 'notifications', where('userId', '==', 'stu1')));
    await assertSucceeds(updateDoc(doc(db('stu1'), 'notifications/n_stu1'), { isRead: true }));
  });

  test('suspended student still reads own records', async () => {
    await assertSucceeds(read(db('stuSuspended'), 'users/stuSuspended'));
    await assertSucceeds(read(db('stuSuspended'), 'exams/eSuspended'));
  });

  test('reads course content and active mosques', async () => {
    await assertSucceeds(read(db('stu1'), 'courses/c1'));
    await assertSucceeds(read(db('stu1'), 'question_bank/q1'));
    await assertSucceeds(list(db('stu1'), 'exam_segments'));
    await assertSucceeds(list(anonymousDb(), 'mosques', where('isActive', '==', true)));
  });

  test('registers as a student of an active mosque', async () => {
    await assertSucceeds(
      setDoc(doc(db('newcomer'), 'users/newcomer'), {
        ...account('newcomer', 'student', inS1), createdAt: now(), updatedAt: now(),
      }),
    );
  });

  test('uploads, replaces and listens to own recording', async () => {
    const recording = ref(storage('stu1'), recordingPath('eOpen'));
    await assertSucceeds(uploadBytes(recording, audio(), m4a));
    await assertSucceeds(getBytes(recording));
    await assertSucceeds(listen('stu1', 'e1'));
  });
});

describe('allowed: active supervisor in the square', () => {
  test('reads the examinations of the square', async () => {
    await assertSucceeds(read(db('sup1'), 'exams/e1'));
    const exams = await assertSucceeds(
      list(db('sup1'), 'exams', where('squareId', '==', 's1')),
    );
    assert.equal(exams.size, 4);
    await assertSucceeds(
      list(db('sup1'), 'exams', where('squareId', '==', 's1'), where('status', '==', 'pending_review')),
    );
  });

  test('reads what a review needs', async () => {
    await assertSucceeds(read(db('sup1'), 'squares/s1'));
    await assertSucceeds(read(db('sup1'), 'users/stu1'));
    await assertSucceeds(
      list(db('sup1'), 'users', where('role', '==', 'student'), where('squareId', '==', 's1')),
    );
    await assertSucceeds(read(db('sup1'), 'submissions/e1'));
    await assertSucceeds(read(db('sup1'), 'exam_questions/e1_1'));
    await assertSucceeds(read(db('sup1'), 'question_answers/q1'));
    await assertSucceeds(read(db('sup1'), 'evaluations/eA'));
    await assertSucceeds(read(db('sup1'), 'certificates/eA'));
  });

  test('reads and marks the notifications of the square', async () => {
    await assertSucceeds(list(db('sup1'), 'notifications', where('squareId', '==', 's1')));
    await assertSucceeds(updateDoc(doc(db('sup1'), 'notifications/n_s1'), { isRead: true }));
  });

  test('listens to a submitted recording of the square', async () => {
    await assertSucceeds(listen('sup1', 'e1'));
  });
});

describe('allowed: region officer in the region', () => {
  test('reads the region', async () => {
    await assertSucceeds(read(db('officer1'), 'regions/r1'));
    await assertSucceeds(list(db('officer1'), 'squares', where('regionId', '==', 'r1')));
    await assertSucceeds(list(db('officer1'), 'mosques', where('regionId', '==', 'r1')));
    await assertSucceeds(list(db('officer1'), 'exams', where('regionId', '==', 'r1')));
    await assertSucceeds(list(db('officer1'), 'users', where('regionId', '==', 'r1')));
    await assertSucceeds(read(db('officer1'), 'users/sup1'));
    await assertSucceeds(read(db('officer1'), 'evaluations/eA'));
    await assertSucceeds(read(db('officer1'), 'certificates/eA'));
    await assertSucceeds(listen('officer1', 'e1'));
  });

  test('manages the squares and mosques of the region', async () => {
    await assertSucceeds(
      setDoc(doc(db('officer1'), 'squares/new'), {
        name: 'New', regionId: 'r1', supervisorId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('officer1'), 'squares/s1'), { name: 'Renamed', updatedAt: now() }),
    );
    await assertSucceeds(
      setDoc(doc(db('officer1'), 'mosques/new'), {
        name: 'New', address: '', squareId: 's1', regionId: 'r1', isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('officer1'), 'mosques/m3'), { isActive: true, updatedAt: now() }),
    );
  });

  test('suspends a supervisor and a student of the region', async () => {
    await assertSucceeds(
      updateDoc(doc(db('officer1'), 'users/sup1'), { isActive: false, updatedAt: now() }),
    );
    await assertSucceeds(
      updateDoc(doc(db('officer1'), 'users/stu1'), { isActive: false, updatedAt: now() }),
    );
  });
});

describe('allowed: General Admin', () => {
  test('reads the administrative data of the whole system', async () => {
    await assertSucceeds(list(db('admin'), 'regions'));
    await assertSucceeds(list(db('admin'), 'squares'));
    await assertSucceeds(list(db('admin'), 'mosques'));
    await assertSucceeds(list(db('admin'), 'users'));
    await assertSucceeds(list(db('admin'), 'exams'));
    await assertSucceeds(read(db('admin'), 'evaluations/eB'));
    await assertSucceeds(read(db('admin'), 'staff_invites/invited'));
    await assertSucceeds(listen('admin', 'e2'));
  });

  test('manages regions, squares and accounts', async () => {
    await assertSucceeds(
      setDoc(doc(db('admin'), 'regions/new'), {
        name: 'New', description: '', officerId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('admin'), 'regions/r1'), { isActive: false, updatedAt: now() }),
    );
    await assertSucceeds(
      setDoc(doc(db('admin'), 'squares/new'), {
        name: 'New', regionId: 'r2', supervisorId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('admin'), 'users/officer1'), { isActive: false, updatedAt: now() }),
    );
    await assertSucceeds(
      setDoc(doc(db('admin'), 'staff_invites/newOfficer'), {
        name: 'Officer', email: 'newOfficer@test.dev', phone: '0590000000',
        role: 'region_officer', regionId: 'r2', squareId: null,
        createdBy: 'admin', createdAt: now(),
      }),
    );
  });
});

// ===========================================================================
// The batches the application writes: getAfter, existsAfter, validUnitLink
// and the document access limits.
// ===========================================================================

function startExamBatch(uid, examId, scope = inS1) {
  const firestore = db(uid);
  const batch = writeBatch(firestore);
  batch.set(doc(firestore, `exams/${examId}`), {
    ...exam(uid, scope, 'in_progress'),
    startedAt: now(), createdAt: now(), updatedAt: now(),
  });
  for (let order = 1; order <= 10; order++) {
    batch.set(
      doc(firestore, `exam_questions/${examId}_${order}`),
      examQuestion(examId, uid, order),
    );
  }
  return batch;
}

function submitBatch(uid, examId, squareId = 's1') {
  const firestore = db(uid);
  const batch = writeBatch(firestore);
  batch.set(doc(firestore, `submissions/${examId}`), {
    ...submission(examId, uid), submittedAt: now(), createdAt: now(),
  });
  batch.update(doc(firestore, `exams/${examId}`), {
    status: 'pending_review', submittedAt: now(), updatedAt: now(),
  });
  batch.set(doc(firestore, `notifications/${examId}_submitted`), {
    ...notification({ squareId }), relatedId: examId, createdAt: now(),
  });
  return batch;
}

function approveBatch(uid, examId, studentId, scores, withCertificate, report = {}) {
  const firestore = db(uid);
  const finalScore = scores.recitation + scores.theory;
  const batch = writeBatch(firestore);
  batch.update(doc(firestore, `exams/${examId}`), {
    status: 'approved', reviewedAt: now(), approvedAt: now(), updatedAt: now(),
  });
  batch.set(doc(firestore, `evaluations/${examId}`), {
    examId,
    supervisorId: uid,
    recitationScore: scores.recitation,
    theoryScore: scores.theory,
    finalScore,
    result: finalScore >= 70 ? 'passed' : 'failed',
    feedback: null,
    detailedErrors: [],
    status: 'approved',
    reviewedAt: now(),
    approvedAt: now(),
    ...report,
  });
  batch.set(doc(firestore, `notifications/${examId}_result`), {
    ...notification({ userId: studentId }), relatedId: examId, createdAt: now(),
  });
  if (withCertificate) {
    batch.set(doc(firestore, `certificates/${examId}`), {
      ...certificate(examId, studentId), finalScore, issuedAt: now(),
    });
  }
  return batch;
}

describe('batches: examination', () => {
  test('student starts an examination with its ten questions', async () => {
    await assertSucceeds(startExamBatch('stu1', 'started').commit());
  });

  test('student cannot add questions to a submitted examination', async () => {
    await assertFails(
      setDoc(doc(db('stu1'), 'exam_questions/e1_2'), examQuestion('e1', 'stu1', 2)),
    );
  });

  test('student cannot write questions for another student\'s examination', async () => {
    await assertFails(
      setDoc(doc(db('stu1x'), 'exam_questions/eOpen_2'), examQuestion('eOpen', 'stu1x', 2)),
    );
  });

  test('student submits: submission, examination and notification', async () => {
    await assertSucceeds(submitBatch('stu1', 'eOpen').commit());
  });

  test('student cannot submit twice', async () => {
    await assertFails(submitBatch('stu1', 'e1').commit());
  });

  test('suspended student cannot submit', async () => {
    await assertFails(submitBatch('stuSuspended', 'eSuspended').commit());
  });

  test('submission notification cannot go to another square', async () => {
    await assertFails(submitBatch('stu1', 'eOpen', 's2').commit());
  });

  test('submission must hold ten well-formed answers', async () => {
    const firestore = db('stu1');
    const batch = writeBatch(firestore);
    batch.set(doc(firestore, 'submissions/eOpen'), {
      ...submission('eOpen', 'stu1'),
      answers: answers().map((a) => ({ ...a, score: 2 })),
      submittedAt: now(), createdAt: now(),
    });
    batch.update(doc(firestore, 'exams/eOpen'), {
      status: 'pending_review', submittedAt: now(), updatedAt: now(),
    });
    await assertFails(batch.commit());
  });
});

describe('batches: approval', () => {
  const passed = { recitation: 70, theory: 18 };
  const failed = { recitation: 40, theory: 10 };

  test('supervisor approves a passed result with its certificate', async () => {
    await assertSucceeds(approveBatch('sup1', 'e1', 'stu1', passed, true).commit());
  });

  test('supervisor approves a failed result without a certificate', async () => {
    await assertSucceeds(approveBatch('sup1', 'e1', 'stu1', failed, false).commit());
  });

  test('failed result never gets a certificate', async () => {
    await assertFails(approveBatch('sup1', 'e1', 'stu1', failed, true).commit());
  });

  test('examination cannot be approved twice', async () => {
    await assertFails(approveBatch('sup1', 'eA', 'stu1', passed, false).commit());
  });

  test('examination in progress cannot be approved', async () => {
    await assertFails(approveBatch('sup1', 'eOpen', 'stu1', passed, true).commit());
  });

  test('supervisor of another square, officer and admin cannot approve', async () => {
    await assertFails(approveBatch('sup1b', 'e1', 'stu1', passed, true).commit());
    await assertFails(approveBatch('sup2', 'e1', 'stu1', passed, true).commit());
    await assertFails(approveBatch('officer1', 'e1', 'stu1', passed, true).commit());
    await assertFails(approveBatch('admin', 'e1', 'stu1', passed, true).commit());
  });

  test('scores out of range or inconsistent are refused', async () => {
    await assertFails(
      approveBatch('sup1', 'e1', 'stu1', { recitation: 81, theory: 18 }, true).commit(),
    );
    await assertFails(
      approveBatch('sup1', 'e1', 'stu1', { recitation: 70, theory: 21 }, true).commit(),
    );
  });

  const approveWith = (report, uid = 'sup1') =>
    approveBatch(uid, 'e1', 'stu1', passed, true, report).commit();

  test('supervisor approves with notes and detailed errors, and the student reads them', async () => {
    await assertSucceeds(
      approveWith({
        feedback: 'راجع أحكام النون الساكنة',
        detailedErrors: [
          detailedError('error-1'),
          detailedError('error-2', { ruleName: null, ayahNumber: null, word: null, description: '' }),
        ],
      }),
    );

    const saved = await assertSucceeds(read(db('stu1'), 'evaluations/e1'));
    assert.equal(saved.data().feedback, 'راجع أحكام النون الساكنة');
    assert.equal(saved.data().detailedErrors.length, 2);
    assert.equal(saved.data().detailedErrors[0].ruleId, 'rule1');
    assert.equal(saved.data().detailedErrors[0].ayahNumber, 3);
    assert.equal(saved.data().detailedErrors[1].word, null);

    await assertSucceeds(read(db('sup1'), 'evaluations/e1'));
    await assertSucceeds(read(db('officer1'), 'evaluations/e1'));
    await assertSucceeds(read(db('admin'), 'evaluations/e1'));
    await assertFails(read(db('stu1x'), 'evaluations/e1'));
    await assertFails(read(db('sup1b'), 'evaluations/e1'));
    await assertFails(read(db('officer2'), 'evaluations/e1'));
  });

  test('twenty detailed errors are accepted, twenty-one refused', async () => {
    const full = (id) =>
      detailedError(id, {
        ruleName: 'ق'.repeat(200),
        word: 'ك'.repeat(60),
        description: 'و'.repeat(300),
        ayahNumber: 286,
      });
    await assertFails(
      approveWith({ detailedErrors: Array.from({ length: 21 }, (_, i) => full(`error-${i}`)) }),
    );
    await assertSucceeds(
      approveWith({ detailedErrors: Array.from({ length: 20 }, (_, i) => full(`error-${i}`)) }),
    );
  });

  test('detailed errors that are not a list of errors with a rule are refused', async () => {
    const withError = (change) => approveWith({ detailedErrors: [detailedError('error-1', change)] });
    const { ruleId, ...withoutRule } = detailedError('error-1');

    await assertFails(approveWith({ detailedErrors: null }));
    await assertFails(approveWith({ detailedErrors: 'خطأ' }));
    await assertFails(approveWith({ detailedErrors: { 0: detailedError('error-1') } }));
    await assertFails(approveWith({ detailedErrors: ['خطأ'] }));
    await assertFails(approveWith({ detailedErrors: [withoutRule] }));
    await assertFails(withError({ ruleId: null }));
    await assertFails(withError({ ruleId: 7 }));
    // An error without a rule after well-formed ones is still caught.
    await assertFails(
      approveWith({ detailedErrors: [...detailedErrors(19), detailedError('error-20', { ruleId: 7 })] }),
    );
  });

  test('evaluation without the detailedErrors field is refused', async () => {
    const firestore = db('sup1');
    const batch = writeBatch(firestore);
    batch.update(doc(firestore, 'exams/e1'), {
      status: 'approved', reviewedAt: now(), approvedAt: now(), updatedAt: now(),
    });
    const { detailedErrors: _, ...withoutErrors } = evaluation('e1', 'sup1');
    batch.set(doc(firestore, 'evaluations/e1'), {
      ...withoutErrors, reviewedAt: now(), approvedAt: now(),
    });
    batch.set(doc(firestore, 'notifications/e1_result'), {
      ...notification({ userId: 'stu1' }), relatedId: 'e1', createdAt: now(),
    });
    await assertFails(batch.commit());
  });

  test('notes longer than the limit are refused', async () => {
    await assertFails(approveWith({ feedback: 'م'.repeat(2001) }));
    await assertSucceeds(approveWith({ feedback: 'م'.repeat(2000) }));
  });

  test('detailed errors do not let another square, an officer or a student approve', async () => {
    const report = { feedback: 'ملاحظة', detailedErrors: detailedErrors(2) };
    await assertFails(approveWith(report, 'sup1b'));
    await assertFails(approveWith(report, 'sup2'));
    await assertFails(approveWith(report, 'supInactive'));
    await assertFails(approveWith(report, 'officer1'));
    await assertFails(approveWith(report, 'admin'));
    await assertFails(approveWith(report, 'stu1'));
  });

  test('an approved evaluation is never changed, even by its supervisor', async () => {
    const saved = doc(db('sup1'), 'evaluations/eA');
    await assertFails(updateDoc(saved, { feedback: 'تعديل' }));
    await assertFails(updateDoc(saved, { detailedErrors: [] }));
    await assertFails(updateDoc(saved, { recitationScore: 80, finalScore: 98 }));
    await assertFails(deleteDoc(saved));
    await assertFails(updateDoc(doc(db('officer1'), 'evaluations/eA'), { feedback: 'تعديل' }));
    await assertFails(updateDoc(doc(db('admin'), 'evaluations/eA'), { detailedErrors: [] }));
  });

  test('evaluation alone, without approving the examination, is refused', async () => {
    await assertFails(
      setDoc(doc(db('sup1'), 'evaluations/e1'), {
        ...evaluation('e1', 'sup1'), reviewedAt: now(), approvedAt: now(),
      }),
    );
  });

  test('certificate for an examination approved earlier is refused', async () => {
    await env.withSecurityRulesDisabled((context) =>
      deleteDoc(doc(context.firestore(), 'certificates/eA')),
    );
    await assertFails(
      setDoc(doc(db('sup1'), 'certificates/eA'), {
        ...certificate('eA', 'stu1'), issuedAt: now(),
      }),
    );
  });
});

function moveMosqueBatch(uid, mosqueId, target, studentIds) {
  const firestore = db(uid);
  const batch = writeBatch(firestore);
  const change = { ...target, updatedAt: now() };
  batch.update(doc(firestore, `mosques/${mosqueId}`), change);
  for (const studentId of studentIds) {
    batch.update(doc(firestore, `users/${studentId}`), change);
  }
  return batch;
}

const crowd = (count) =>
  Object.fromEntries(
    Array.from({ length: count }, (_, i) => [
      `users/crowd${i}`,
      account(`crowd${i}`, 'student', inS1),
    ]),
  );
const crowdIds = (count) => Array.from({ length: count }, (_, i) => `crowd${i}`);
const m1Students = ['stu1', 'stu1x', 'stuSuspended'];

describe('batches: moving a mosque (getAfter on the mosque)', () => {
  test('officer moves a mosque and its students within the region', async () => {
    await assertSucceeds(
      moveMosqueBatch('officer1', 'm1', { squareId: 's1b', regionId: 'r1' }, m1Students).commit(),
    );
  });

  test('General Admin moves a mosque and its students to another region', async () => {
    await assertSucceeds(
      moveMosqueBatch('admin', 'm1', { squareId: 's2', regionId: 'r2' }, m1Students).commit(),
    );
  });

  test('officer cannot move a mosque and its students out of the region', async () => {
    await assertFails(
      moveMosqueBatch('officer1', 'm1', { squareId: 's2', regionId: 'r2' }, m1Students).commit(),
    );
  });

  test('student cannot be moved without the mosque', async () => {
    await assertFails(
      updateDoc(doc(db('admin'), 'users/stu1'), {
        squareId: 's1b', regionId: 'r1', updatedAt: now(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('officer1'), 'users/stu1'), { squareId: 's1b', updatedAt: now() }),
    );
  });

  test('mosque cannot be given a square of another region', async () => {
    await assertFails(
      updateDoc(doc(db('admin'), 'mosques/m1'), { squareId: 's2', updatedAt: now() }),
    );
  });

  test('30 students move in one batch', async () => {
    await seedFirestore(crowd(30));
    await assertSucceeds(
      moveMosqueBatch(
        'officer1', 'm1', { squareId: 's1b', regionId: 'r1' },
        [...m1Students, ...crowdIds(30)],
      ).commit(),
    );
  });

  test('450 students move in one batch (the application\'s limit)', async () => {
    await seedFirestore(crowd(450));
    await assertSucceeds(
      moveMosqueBatch(
        'admin', 'm1', { squareId: 's2', regionId: 'r2' }, crowdIds(450),
      ).commit(),
    );
  });
});

describe('batches: staff (validUnitLink, getAfter on the account)', () => {
  test('officer moves a supervisor to another square of the region', async () => {
    const firestore = db('officer1');
    const batch = writeBatch(firestore);
    batch.update(doc(firestore, 'users/supNoSquare'), {
      regionId: 'r1', squareId: 's1b', updatedAt: now(),
    });
    batch.update(doc(firestore, 'squares/s1b'), { supervisorId: 'supNoSquare', updatedAt: now() });
    await assertSucceeds(batch.commit());
  });

  test('supervisor leaves one square for another: unlink, move, link', async () => {
    await env.withSecurityRulesDisabled((context) =>
      updateDoc(doc(context.firestore(), 'squares/s1b'), { supervisorId: null }),
    );
    const firestore = db('officer1');
    const batch = writeBatch(firestore);
    batch.update(doc(firestore, 'users/sup1'), {
      regionId: 'r1', squareId: 's1b', updatedAt: now(),
    });
    batch.update(doc(firestore, 'squares/s1'), { supervisorId: null, updatedAt: now() });
    batch.update(doc(firestore, 'squares/s1b'), { supervisorId: 'sup1', updatedAt: now() });
    await assertSucceeds(batch.commit());
  });

  test('General Admin moves an officer to another region', async () => {
    const firestore = db('admin');
    const batch = writeBatch(firestore);
    batch.update(doc(firestore, 'users/officer1'), {
      regionId: 'r2', squareId: null, updatedAt: now(),
    });
    batch.update(doc(firestore, 'regions/r1'), { officerId: null, updatedAt: now() });
    batch.update(doc(firestore, 'regions/r2'), { officerId: 'officer1', updatedAt: now() });
    await assertSucceeds(batch.commit());
  });

  test('square cannot name a student, an officer or a missing account', async () => {
    for (const supervisorId of ['stu1', 'officer1', 'nobody']) {
      await assertFails(
        updateDoc(doc(db('officer1'), 'squares/s1'), { supervisorId, updatedAt: now() }),
      );
    }
  });

  test('square cannot name the supervisor of another square', async () => {
    await assertFails(
      updateDoc(doc(db('officer1'), 'squares/s1'), { supervisorId: 'sup1b', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('admin'), 'squares/s1'), { supervisorId: 'sup2', updatedAt: now() }),
    );
  });

  test('region cannot name the officer of another region, or a supervisor', async () => {
    await assertFails(
      updateDoc(doc(db('admin'), 'regions/r1'), { officerId: 'officer2', updatedAt: now() }),
    );
    await assertFails(
      updateDoc(doc(db('admin'), 'regions/r1'), { officerId: 'sup1', updatedAt: now() }),
    );
  });

  test('unit keeps the account it already names when another field changes', async () => {
    await assertSucceeds(
      updateDoc(doc(db('admin'), 'regions/r1'), { name: 'Renamed', updatedAt: now() }),
    );
  });

  test('staff account: invitation, own profile, link', async () => {
    const invite = {
      name: 'New', email: 'newSup@test.dev', phone: '0590000000',
      role: 'square_supervisor', regionId: 'r1', squareId: 's1b',
    };
    await assertSucceeds(
      setDoc(doc(db('officer1'), 'staff_invites/newSup'), {
        ...invite, createdBy: 'officer1', createdAt: now(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db('newSup'), 'users/newSup'), {
        uid: 'newSup', ...invite, mosqueId: null, isActive: true,
        createdAt: now(), updatedAt: now(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('officer1'), 'squares/s1b'), { supervisorId: 'newSup', updatedAt: now() }),
    );
    await assertSucceeds(read(db('newSup'), 'squares/s1b'));
  });

  test('invited account creates its profile from the seeded invitation', async () => {
    await assertSucceeds(
      setDoc(doc(db('invited'), 'users/invited'), {
        ...account('invited', 'square_supervisor', { regionId: 'r1', squareId: 's1b' }),
        createdAt: now(), updatedAt: now(),
      }),
    );
  });
});
