// Grades the examinations submitted before the theory score was saved on
// submission. Run once, after the functions are deployed and before the new
// security rules are:
//
//   node tools/backfill_pending.mjs --project ai-quran-exam --dry-run
//   node tools/backfill_pending.mjs --project ai-quran-exam --apply
//
// The credentials are the Application Default Credentials of the machine:
// either `gcloud auth application-default login`, or the path of a
// service-account key in GOOGLE_APPLICATION_CREDENTIALS. The key is kept
// outside the project and is never committed.
//
// When FIRESTORE_EMULATOR_HOST is set, the tool talks to the emulator instead
// and needs no credentials.
//
// An incomplete examination is listed and left as it is. See
// `src/backfill.js`.
import { parseArgs } from 'node:util';

import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { backfillPendingEvaluations } from '../src/backfill.js';

const usage =
  'Give --project and exactly one of --dry-run or --apply.\n' +
  '  node tools/backfill_pending.mjs --project <id> --dry-run | --apply';

let options;
try {
  options = parseArgs({
    options: {
      project: { type: 'string' },
      'dry-run': { type: 'boolean', default: false },
      apply: { type: 'boolean', default: false },
    },
  }).values;
} catch (error) {
  console.error(`${error.message}\n\n${usage}`);
  process.exit(64);
}
if (!options.project || options['dry-run'] === options.apply) {
  console.error(usage);
  process.exit(64);
}

initializeApp({ projectId: options.project });
const report = await backfillPendingEvaluations(getFirestore(), {
  apply: options.apply,
});

const target = process.env.FIRESTORE_EMULATOR_HOST
  ? `emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`
  : `project ${options.project}`;
console.log(`Examinations awaiting review in the ${target}:`);
console.log(
  `  ${options.apply ? 'graded' : 'would be graded'}: ${report.graded.length}`,
);
for (const examId of report.graded) console.log(`    ${examId}`);
console.log(`  already graded: ${report.alreadyGraded.length}`);
console.log(`  incomplete, left as they are: ${report.incomplete.length}`);
for (const { examId, reason } of report.incomplete) {
  console.log(`    ${examId}: ${reason}`);
}
if (!options.apply) console.log('Dry run: nothing was written.');
