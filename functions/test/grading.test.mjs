// Tests of the checks and the scoring. They need no emulator:
//
//   npm --prefix functions run test:unit
import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import {
  answerKeyFrom,
  examQuestionsFrom,
  gradeTheory,
  storedAnswerKey,
  submittedAnswersFrom,
} from '../src/grading.js';

const orders = Array.from({ length: 10 }, (_, index) => index + 1);

const questionDocuments = () =>
  orders.map((order) => ({
    examId: 'e1',
    studentId: 'stu1',
    questionId: `q${order}`,
    order,
    type: 'multiple_choice',
    question: `سؤال ${order}`,
    options: ['أ', 'ب', 'ج', 'د'],
  }));

const questions = () => examQuestionsFrom('e1', questionDocuments());

/** Answers that choose 'أ', the first [wrong] of them choosing 'ب'. */
const answers = (wrong = 0) =>
  orders.map((order) => ({
    order,
    questionId: `q${order}`,
    answer: order <= wrong ? 'ب' : 'أ',
  }));

const key = () =>
  answerKeyFrom(questions(), new Map(orders.map((order) => [`q${order}`, 'أ'])));

describe('examQuestionsFrom', () => {
  test('reads the ten questions in their order', () => {
    const read = questions();
    assert.equal(read.length, 10);
    assert.deepEqual(read[2], {
      order: 3,
      questionId: 'q3',
      options: ['أ', 'ب', 'ج', 'د'],
    });
  });

  test('refuses an examination without its ten questions', () => {
    const documents = questionDocuments();
    assert.equal(examQuestionsFrom('e1', documents.slice(0, 9)), null);
    documents[4] = undefined;
    assert.equal(examQuestionsFrom('e1', documents), null);
    assert.equal(examQuestionsFrom('e1', []), null);
  });

  test('refuses a question of another examination or at another order', () => {
    const other = questionDocuments();
    other[0] = { ...other[0], examId: 'e2' };
    assert.equal(examQuestionsFrom('e1', other), null);

    const moved = questionDocuments();
    moved[0] = { ...moved[0], order: 2 };
    assert.equal(examQuestionsFrom('e1', moved), null);

    const unnamed = questionDocuments();
    unnamed[9] = { ...unnamed[9], questionId: '' };
    assert.equal(examQuestionsFrom('e1', unnamed), null);
  });

  test('refuses a source question that is repeated', () => {
    const repeated = questionDocuments();
    repeated[9] = { ...repeated[9], questionId: 'q1' };
    assert.equal(examQuestionsFrom('e1', repeated), null);
  });
});

describe('submittedAnswersFrom', () => {
  test('keeps only the order, the question and the answer', () => {
    const sent = answers().map((answer) => ({ ...answer, score: 2 }));
    assert.deepEqual(submittedAnswersFrom(questions(), sent), answers());
  });

  test('puts the answers in the order of the questions', () => {
    assert.deepEqual(
      submittedAnswersFrom(questions(), answers().reverse()),
      answers(),
    );
  });

  test('refuses fewer or more than ten answers', () => {
    assert.equal(submittedAnswersFrom(questions(), answers().slice(1)), null);
    assert.equal(
      submittedAnswersFrom(questions(), [...answers(), answers()[0]]),
      null,
    );
    assert.equal(submittedAnswersFrom(questions(), undefined), null);
    assert.equal(submittedAnswersFrom(questions(), 'أ'), null);
  });

  test('refuses two answers to one question', () => {
    const sent = answers();
    sent[9] = { ...sent[0] };
    assert.equal(submittedAnswersFrom(questions(), sent), null);
  });

  test('refuses an answer to a question the examination does not hold', () => {
    const sent = answers();
    sent[3] = { ...sent[3], questionId: 'q99' };
    assert.equal(submittedAnswersFrom(questions(), sent), null);
  });

  test('refuses an empty answer or one that is not an option', () => {
    for (const answer of ['', 'هـ', 7, null, 'أ'.repeat(501)]) {
      const sent = answers();
      sent[0] = { ...sent[0], answer };
      assert.equal(submittedAnswersFrom(questions(), sent), null, `${answer}`);
    }
  });
});

describe('answerKeyFrom and storedAnswerKey', () => {
  test('the key names the correct answer of every question', () => {
    assert.deepEqual(key()[0], { order: 1, questionId: 'q1', correctAnswer: 'أ' });
    assert.equal(key().length, 10);
  });

  test('there is no key when a correct answer is missing', () => {
    const correct = new Map(orders.map((order) => [`q${order}`, 'أ']));
    correct.delete('q7');
    assert.equal(answerKeyFrom(questions(), correct), null);
    correct.set('q7', '');
    assert.equal(answerKeyFrom(questions(), correct), null);
  });

  test('a stored key is read back as it was written', () => {
    assert.deepEqual(storedAnswerKey(questions(), key()), key());
  });

  test('a stored key of other questions is refused', () => {
    const other = key();
    other[2] = { ...other[2], questionId: 'q99' };
    assert.equal(storedAnswerKey(questions(), other), null);
    assert.equal(storedAnswerKey(questions(), key().slice(0, 9)), null);
    assert.equal(storedAnswerKey(questions(), undefined), null);
  });
});

describe('gradeTheory', () => {
  test('every question is worth two marks out of twenty', () => {
    assert.deepEqual(gradeTheory(key(), answers()), {
      correctCount: 10,
      theoryScore: 20,
    });
    assert.deepEqual(gradeTheory(key(), answers(3)), {
      correctCount: 7,
      theoryScore: 14,
    });
    assert.deepEqual(gradeTheory(key(), answers(10)), {
      correctCount: 0,
      theoryScore: 0,
    });
  });

  test('the answer is compared with the key as text', () => {
    const spaced = answers();
    spaced[0] = { ...spaced[0], answer: 'أ ' };
    assert.equal(gradeTheory(key(), spaced).theoryScore, 18);
  });
});
