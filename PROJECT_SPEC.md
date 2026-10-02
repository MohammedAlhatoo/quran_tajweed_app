# Quran Tajweed Testing Platform

## Project Specification

**Project Type:** Graduation Project
**Technology:** Flutter + Firebase
**Qur'an Standard:** Hafs 'an Asim
**Mushaf:** Madinah Mushaf — 604 Pages
**Current Development Phase:** Phase 1 — Manual Supervisor Evaluation
**AI:** Not implemented in Phase 1

---

# Approved Phase 1 Decisions

The following decisions are approved and take priority over any other wording in this document.

1. **Scope:** Phase 1 is the current final project and the only phase being implemented now. Phase 2 and Phase 3 are Future Work only; no part of them is implemented now.
2. **Cloud Functions:** Cloud Functions are not part of Phase 1 currently. They are added only if an essential Phase 1 requirement cannot be implemented securely and correctly without a trusted backend. Any such need is evaluated when the actual requirement is implemented. Cloud Functions are not considered part of the current architecture merely because they may be useful in the future.
3. **User registration:**
   * Students can self-register.
   * Students do not choose their role.
   * The first General Admin account is created manually during system setup.
   * The General Admin creates Region Officer and Square Supervisor accounts from inside the admin panel.
   * There is no self-registration for supervisors, region officers, or admins.
   * No registration screen allows a user to choose a role.
4. **Roles:** The system is a single multi-role Flutter application, not separate applications. Approved roles: `student`, `square_supervisor`, `region_officer`, `general_admin`. After login, the user is routed according to role and permissions.
5. **Users:** The main Firestore collection for accounts is `users`. A `students` collection is not used as the primary accounts collection. The user type is determined by the `role` field.
6. **Quran text:** The Quran text is not stored in Firestore. It is static data inside the Flutter application (Hafs 'an Asim, Madinah Mushaf, 604 pages).
7. **Segment selection:** Quran data is linked to Tajweed rule data for ayahs/segments and pages. This linking data is stored in Firestore (predefined segments in `exam_segments`, rule definitions in `tajweed_rules`). The system selects segments randomly according to the course type and its rules, taking Rule Density into account. This works in Phase 1 without AI.
8. **Scoring:** Final score is out of 100 — 80% recitation, 20% theory questions. The approved pass mark is 70/100.
9. **Target platforms:** Phase 1 targets Android and iOS. The project stays a multi-platform Flutter application and is not restricted to Android.
10. **Application ID:** The current `applicationId` (`com.example.quran_tajweed_app`) is kept as is for now.
11. **Routing:** `go_router` is the approved centralized routing solution.
12. **Existing placeholder files:** The empty files under `lib/` (all except `firebase_options.dart`) are rewritten from scratch according to the architecture in sections 38–42, each in its own implementation step. No unnecessary demo content is kept.
13. **Packages and structure:** No package or structure outside this specification is added without a clear reason.
14. **Trusted backend for examinations:** Creating an examination (choosing the segment and questions) and grading the theory questions are approved in principle to run in Cloud Functions, because they cannot be made secure from the client. This is deferred: no Cloud Functions, Blaze upgrade, or paid setup is done now. Until then the examination is created from the student's device behind a repository interface that a backend can replace. Known interim limits: the random selection is not enforced by the security rules, and the one-examination-per-course checks are enforced only in the application.
15. **Correct answers:** `correctAnswer` is not stored in `question_bank`. It is stored in a separate `question_answers` collection, keyed by the question ID, that students cannot read.
16. **Examination affiliation:** Each `exams` document stores the student's `mosqueId`, `squareId`, and `regionId` at the time the examination is started.
17. **Examination limits:** A student has at most one open examination per course; starting again continues it with the same segment and questions. A new examination in a course cannot be started while one in that course is awaiting review. Examinations have no time limit.
18. **Segment selection algorithm:** Among the active segments of the course, each segment's weight is `ruleDensity × the sum of the weights (from course_rules) of the course rules present in the segment`. One segment is chosen at random with probability proportional to its weight. Segments with zero weight are not eligible.
19. **Quran text and font:** No Quran text file or Mushaf font is added without explicit approval of its source. Until an approved text and font are added, the examination screen shows the segment reference without the ayah text.

---

# 1. Project Overview

The project is an interactive digital platform for testing Quran recitation and Tajweed.

The platform allows Quran students to complete recitation and theoretical Tajweed examinations remotely instead of requiring all examinations to take place physically at Quran centers or mosques.

The current Phase 1 focuses on manual evaluation by approved supervisors.

The system will later support AI-assisted recitation analysis through external AI APIs and eventually a custom Tajweed analysis model.

---

# 2. Main Problem

Due to difficulties that may prevent students and supervisors from conducting Quran and Tajweed examinations in person, especially in areas where access to Quran centers and mosques may be disrupted, there is a need for a digital examination platform.

The platform allows:

* Students to submit Quran recitation recordings remotely.
* Students to answer theoretical Tajweed questions.
* Supervisors to review submissions remotely.
* Supervisors to evaluate recitation and review answers.
* Students to receive their final results.
* Certificates to be generated after successful approval.

---

# 3. Project Goals

The system aims to:

1. Digitize Quran and Tajweed examinations.
2. Allow students to complete examinations remotely.
3. Provide structured Tajweed courses.
4. Organize students according to geographic and administrative hierarchy.
5. Allow supervisors to review examination submissions.
6. Store recitation recordings securely.
7. Provide theoretical Tajweed questions.
8. Calculate examination scores automatically.
9. Generate certificates after approval.
10. Provide notifications for important examination events.
11. Prepare the system for future AI-based recitation analysis.
12. Support future expansion to multiple Quran institutions.

---

# 4. Phase 1 Scope

The current graduation-project Phase 1 will NOT use AI.

Phase 1 will use:

* Flutter
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Manual supervisor evaluation

The initial deployment target is approximately:

* 4–5 mosques
* 50–70 students

The system should be designed so that it can later scale to more institutions and users.

---

# 5. Administrative Hierarchy

The administrative hierarchy is:

General Admin
↓
Region Officer
↓
Square Supervisor
↓
Mosques
↓
Students

## 5.1 General Admin

The General Admin manages the entire system.

Responsibilities include:

* Managing regions.
* Managing region officers.
* Managing squares.
* Managing square supervisors.
* Managing mosques.
* Managing courses.
* Managing question banks.
* Managing users.
* Viewing system statistics.
* Managing certificates.
* Managing system-wide settings.

---

## 5.2 Region Officer

The Region Officer manages a specific region.

Responsibilities include:

* Viewing squares inside the region.
* Managing the existing supervisors inside the region according to the permissions granted to the Region Officer.
* Viewing mosques.
* Viewing students.
* Viewing examination statistics.
* Monitoring examination activity.

The Region Officer does not create new supervisor accounts. Region Officer and Square Supervisor accounts are created by the General Admin.

The Region Officer must not access unrelated regions.

---

## 5.3 Square Supervisor

A Square Supervisor is responsible for approximately 4–5 mosques.

Responsibilities include:

* Viewing assigned mosques.
* Viewing assigned students.
* Managing the mosques and students belonging to the square according to the permissions granted to the Square Supervisor.
* Reviewing submitted examinations.
* Listening to recitation recordings.
* Reviewing theoretical answers.
* Entering recitation evaluation.
* Viewing the theory score calculated automatically by the system (not entered or modified by the supervisor).
* Approving final examination results.
* Viewing student examination history.

A supervisor must only access students and examinations belonging to the supervisor's assigned square.

---

## 5.4 Student

Students can:

* Sign in.
* View their profile.
* View their mosque (chosen by the student during registration).
* View available courses.
* Start examinations.
* Read the assigned Quran segment.
* Record recitation.
* Answer theoretical Tajweed questions.
* Submit examinations.
* View examination status.
* View approved results.
* View certificates.
* Receive notifications.

Students cannot:

* Modify supervisor evaluations.
* Modify examination results after submission.
* Access other students' data.
* Access administrative data.

---

# 6. User Roles

The system supports four main roles:

```text
student
square_supervisor
region_officer
general_admin
```

The system is a single multi-role Flutter application, not separate applications per role.

The role is stored in the `role` field of the user's document in `users`.

Users never choose their own role. Self-registration always creates a `student`.

Role-based access control must be implemented.

After login, the user is routed according to role and permissions.

Routing and Firebase security rules must respect the user's role.

---

# 7. Quran Standard

The platform uses:

* Riwayah: Hafs 'an Asim
* Mushaf: Madinah Mushaf
* Total pages: 604

The Quran content must be handled carefully and consistently.

The application should not arbitrarily modify Quran text.

The Quran text is not stored in Firestore. It is shipped as static data inside the Flutter application.

---

# 8. Tajweed Courses

The system supports four examination levels:

## 8.1 تمهيدية

Introductory Tajweed level.

## 8.2 تأهيلية

Qualifying Tajweed level.

## 8.3 عليا

Advanced Tajweed level.

## 8.4 السند

Sanad level.

Each course should have its own set of Tajweed rules and question categories.

---

# 9. Tajweed Rules

The system should support a structured Tajweed rule database.

Examples include:

* أحكام النون الساكنة والتنوين
* أحكام الميم الساكنة
* المدود
* الغنة
* أحكام اللام
* أحكام الراء
* القلقلة
* التفخيم والترقيق
* الوقف والابتداء
* السكت
* وغيرها من أحكام التجويد

The exact rules assigned to each course should be stored as structured data instead of being hard-coded into UI screens.

The Tajweed rules themselves are defined in a separate Firestore collection named `tajweed_rules`. It is the reference source for `ruleId` and `ruleIds`.

* `course_rules` links courses to Tajweed rules through `ruleId`.
* `exam_segments.ruleIds` links each segment to the Tajweed rules in `tajweed_rules`.
* The definitions of the Tajweed rules are not placed inside `exam_segments` or `course_rules`; these collections use references only.

---

# 10. Examination Workflow

The examination workflow is:

```text
Student
   ↓
Select Course
   ↓
Start Examination
   ↓
Receive Quran Segment
   ↓
Read / Record Recitation
   ↓
Answer 10 Theory Questions
   ↓
Review Submission
   ↓
Submit Examination
   ↓
System Calculates Theory Score Automatically and Creates Evaluation Record
   ↓
Status = Pending Review
   ↓
Supervisor Reviews
   ↓
Supervisor Evaluates Recitation (Enters Recitation Score)
   ↓
Supervisor Reviews Theory Answers (Cannot Modify Theory Score)
   ↓
System Calculates Final Score
   ↓
Supervisor Approves Result
   ↓
Student Receives Result (passed / failed)
   ↓
Certificate Generated (only if result = passed)
```

---

# 11. Quran Segment Selection

Phase 1 should use a structured Quran segment database: `exam_segments` in Firestore contains predefined segments, and the system selects from them randomly when the examination starts.

A segment is identified by `surah`, `ayahFrom`, `ayahTo`, and `page`.

The selected segment should be appropriate for the student's course.

The selection should consider Tajweed rule density.

The goal is to select Quran segments containing relevant Tajweed rules suitable for the examination level.

The segment may be approximately 5–7 lines or an appropriate portion of a page.

The exact segment selection logic should be implemented as a service rather than inside the UI.

Random segment selection is part of Phase 1 itself and is not deferred to Future Work. It works in Phase 1 without AI.

Selection algorithm: among the active segments whose `courseIds` contain the course, each segment's weight is `ruleDensity × the sum of the course_rules weights of the course rules present in the segment's ruleIds`. One segment is chosen at random with probability proportional to its weight. A segment whose weight is zero is not eligible. If no segment is eligible, the examination cannot be started.

The random selection depends on:

* The course level.
* The Tajweed rules required for the course.
* The rule data linked to ayahs/segments and pages. This data is stored in Firestore, because it is required for random selection according to the course.
* Tajweed Rule Density.

Future versions may introduce AI-assisted selection.

---

# 12. Recitation Recording

The student should have a dedicated recitation screen containing:

* Quran segment.
* Recording button.
* Recording status.
* Recording timer.
* Stop recording button.
* Playback option.
* Re-record option if allowed.
* Submit recording option.

The recording should be uploaded securely to Firebase Storage.

The associated metadata should be stored in Firestore.

---

# 13. Theory Questions

Each examination contains:

**10 theoretical Tajweed questions.**

Questions should be selected according to:

* Course level.
* Tajweed rules included in the course.
* Question difficulty.
* Question category.

The question bank must be stored separately from individual examination submissions.

The system should support multiple question types where appropriate.

Examples:

* Multiple choice.
* True / false.
* Identification of a Tajweed rule.
* Other structured question types.

The exact question types should follow the approved UI design.

---

# 14. Examination Scoring

The final examination score is out of 100.

## Recitation

```text
80%
```

## Theory Questions

```text
20%
```

## Final Score

```text
Final Score = Recitation Score (80) + Theory Score (20)
```

## Pass Mark

```text
70 / 100
```

## Result

The examination result depends on the final score and is stored in a separate result field:

```text
Final Score >= 70 → passed
Final Score < 70  → failed
```

The system should calculate the final score automatically.

In Phase 1, `theoryScore` is calculated automatically when the student submits the examination, after answering the ten questions.

`theoryScore` is stored in `evaluations`, not in `exams` or `submissions`. The system creates the `evaluations` record after the student submits the examination.

`finalScore` is calculated from `recitationScore` (80) + `theoryScore` (20) after the recitation score becomes available.

The detailed technical mechanism for secure grading does not need to be decided now. It is determined during implementation, together with the Firestore Security Rules. Cloud Functions are not assumed as the solution at this stage.

In Phase 1, the source of the theory score is the system's automatic grading, not supervisor entry.

* The supervisor enters the recitation score only, out of 80.
* The system calculates the theory score out of 20 automatically.
* The supervisor can review the student's answers, but cannot modify the theory score calculated by the system.
* The system then calculates the final score using the formula above.

---

# 15. Examination Status

The examination should support statuses such as:

```text
draft
in_progress
submitted
pending_review
under_review
approved
```

Passing and failing are expressed in a separate result field (`passed` / `failed`), not in the status.

A student whose result is `failed` can retake the examination later through a new attempt / new examination. The previous approved examination is not reopened.

An examination is created with the status `in_progress`.

A student has at most one open examination (`draft` or `in_progress`) per course. Starting an examination in a course that already has an open one continues it with the same segment and questions.

A student cannot start a new examination in a course while an examination in that course is awaiting review (`submitted`, `pending_review`, or `under_review`).

Examinations have no time limit.

The exact status transitions must be controlled by the application.

Students should not be able to change an examination from `pending_review` back to an editable state unless explicitly allowed by the business rules.

---

# 16. Supervisor Evaluation

The supervisor should be able to:

1. Open a submitted examination.
2. View student information.
3. View the Quran segment.
4. Listen to the recording.
5. Review theory answers.
6. Enter recitation score (out of 80).
7. View the theory score calculated automatically by the system (out of 20). The supervisor cannot modify it.
8. Add notes or feedback.
9. Review the calculated final score.
10. Approve the result. The result (`passed` / `failed`) is determined by the final score, not by the supervisor rejecting the examination.

Evaluation records should be stored separately from the student's original submission where appropriate.

---

# 17. Certificates

A certificate is available only when both conditions are met:

* The supervisor has approved the result.
* The result is `passed` (Final Score >= 70).

When both conditions are met:

* A certificate record should be created.
* The certificate should be associated with the student.
* The certificate should be associated with the course.
* The certificate should include the final result.
* The certificate should have a unique identifier.
* The certificate should be viewable by the student.
* The certificate may later be downloadable or printable.

---

# 18. Notifications

Notifications for important events are required in Phase 1.

The sending and implementation mechanism is not decided now. It is evaluated when the actual requirement is implemented.

Examples:

* Examination submitted.
* Examination under review.
* Examination approved.
* Result available.
* Certificate available.

Notification records should also be stored in Firestore when appropriate so users can view notification history.

---

# 19. Firebase Architecture

The project uses:

```text
Firebase Authentication
Cloud Firestore
Firebase Storage
```

Cloud Functions are not part of Phase 1 currently and are not part of the current architecture.

* Cloud Functions are added only if an essential Phase 1 requirement cannot be implemented securely and correctly without a trusted backend.
* Any future need for Cloud Functions is evaluated when the actual requirement is implemented.
* Cloud Functions are not considered part of the current architecture merely because they may be useful in the future.

---

# 20. Firebase Authentication

Firebase Authentication is responsible for:

* User registration.
* User login.
* User logout.
* Current user session.
* Authentication state.

User profile and role information should be stored in Firestore.

The Firebase Authentication UID must be used as the primary user identifier.

Account creation rules:

* Students can self-register. A self-registered account is always a `student`.
* The student chooses the mosque during registration from the list of available mosques. The region and square are not chosen manually; the system derives them from the mosque.
* Phase 1 does not add a separate account approval system.
* The student can sign in after registration. The permission to start an examination depends on the student's mosque, square, and region affiliation data being complete.
* The Square Supervisor does not need to manually assign the student to a mosque after registration.
* The first General Admin account is created manually during system setup.
* The General Admin creates Region Officer and Square Supervisor accounts from inside the admin panel.
* There is no self-registration for supervisors, region officers, or admins.
* No registration screen allows a user to choose a role.

"Available mosques" means the mosques where `isActive == true`.

The student registration order is:

```text
1. The student reads the list of active mosques.
2. The student chooses the mosque (mosqueId).
3. The chosen mosque document is read, and squareId and regionId are taken from it.
4. The Firebase Authentication account is created.
5. The users document is created in one write, containing mosqueId, squareId, regionId, and the rest of the account data.
```

The `squares` collection is not read during registration.

There is no period in which the student's `users` document is missing `mosqueId`, `squareId`, or `regionId`.

---

# 21. Firestore Collections

The initial Firestore structure is:

```text
users
regions
squares
mosques
courses
tajweed_rules
course_rules
exams
exam_segments
question_bank
question_answers
exam_questions
submissions
evaluations
certificates
notifications
```

The exact document fields should be defined before implementation.

`users` is the main collection for all accounts. A `students` collection is not used as the primary accounts collection; the user type is determined by the `role` field.

---

# 22. Users Collection

Example fields:

```text
users/{uid}

uid
name
email
phone
role
regionId
squareId
mosqueId
isActive
photoUrl
createdAt
updatedAt
```

Not every role requires every field.

For example:

* Student → mosqueId, squareId, regionId
* Square Supervisor → squareId
* Region Officer → regionId
* General Admin → no geographic restriction

For a student account:

* The student chooses the mosque during registration from the list of available mosques.
* The student does not choose the region or the square manually.
* After the mosque is chosen, the chosen mosque document is read, and `squareId` and `regionId` are taken from it. The `squares` collection is not read during registration.
* The administrative relationship remains mosque → square → region, but the source of the `squareId` and `regionId` values during registration is the chosen mosque document.
* After the Firebase Authentication account is created, the `users` document is created in one write and contains `mosqueId`, `squareId`, `regionId`, and the rest of the account data.
* There is no period in which the `users` document is missing `mosqueId`, `squareId`, or `regionId`.
* The student is not allowed to modify `mosqueId`, `squareId`, or `regionId` after the account is created.

The `isActive` field:

* `isActive` stays in `users`. It is used to activate or deactivate an account administratively when needed.
* The meaning of `isActive` applies to all roles in `users`, not only students.
* When a student registers and the account is created, `isActive = true`.
* There is no approval or manual activation system for the student after registration.
* The supervisor does not need to assign or activate the student after registration.

---

# 23. Regions Collection

Example:

```text
regions/{regionId}

name
description
officerId
isActive
createdAt
updatedAt
```

---

# 24. Squares Collection

Example:

```text
squares/{squareId}

name
regionId
supervisorId
mosqueIds
isActive
createdAt
updatedAt
```

---

# 25. Mosques Collection

Example:

```text
mosques/{mosqueId}

name
regionId
squareId
address
supervisorId
isActive
createdAt
updatedAt
```

---

# 26. Courses Collection

Example:

```text
courses/{courseId}

name
description
level
isActive
createdAt
updatedAt
```

Levels include:

```text
introductory
qualifying
advanced
sanad
```

---

# 27. Course Rules

Example:

```text
course_rules/{courseRuleId}

courseId
ruleId
weight
createdAt
```

This allows each course to define its own Tajweed rule coverage.

`course_rules` links courses to Tajweed rules through `ruleId`, which references `tajweed_rules`. The rule definition itself (such as its name and description) is not stored in `course_rules`.

---

# 28. Exams Collection

Example:

```text
exams/{examId}

studentId
courseId
segmentId
status
mosqueId
squareId
regionId
startedAt
submittedAt
reviewedAt
approvedAt
createdAt
updatedAt
```

`mosqueId`, `squareId`, and `regionId` are copied from the student's `users` document when the examination is started. They let supervisors and region officers query the examinations of their square or region, and let the security rules restrict access to them.

---

# 29. Exam Segments

Example:

```text
exam_segments/{segmentId}

surah
ayahFrom
ayahTo
page
ruleIds
courseIds
difficulty
ruleDensity
isActive
createdAt
```

`exam_segments` stays in Firestore because it holds the segment data needed for random selection and for linking segments to rules and courses.

The segments are predefined in Firestore, and the system selects from them randomly when the examination starts.

`ruleIds` links each segment to the Tajweed rules in `tajweed_rules`. The rule definitions themselves are not stored in `exam_segments`.

`exam_segments` does not store the Quran text. A segment is identified by its reference (`surah`, `ayahFrom`, `ayahTo`, `page`), and its text is read from the static Quran data inside the Flutter application (Hafs 'an Asim, Madinah Mushaf, 604 pages).

The actual Quran data must be handled carefully and should not be duplicated unnecessarily.

---

# 30. Question Bank

The question bank stores reusable questions.

`question_bank` is the main question bank collection and contains the questions available for selection.

A separate collection named `questions` is not used for the same purpose.

Example:

```text
question_bank/{questionId}

courseId
ruleId
type
question
options
difficulty
isActive
createdAt
updatedAt
```

The correct answer is not stored in `question_bank`, because Firestore cannot hide a single field of a readable document. It is stored in a separate collection, with the same document ID as the question:

```text
question_answers/{questionId}

correctAnswer
```

`correctAnswer` must not be sent to the student application during the examination, and must not be included in any examination data the student can read.

Students cannot read `question_answers` through Firestore.

---

# 31. Exam Questions

`exam_questions` is the collection for the questions selected for a specific examination. Each record is linked to the examination by `examId`.

When the examination is created, the system selects 10 questions from `question_bank` according to the course rules and the approved criteria, then saves the selected questions in `exam_questions`.

Selection: 10 active questions of the course, spread across the Tajweed rules. If fewer than 10 are available, the examination cannot be started.

```text
exam_questions/{examId}_{order}

examId
studentId
questionId
order
type
question
options
```

Each record is a copy of the question as shown to the student, without the correct answer. `order` is 1–10. `studentId` is stored so the security rules can restrict each record to its student.

The selected questions for an individual examination should be associated with that examination.

The system must preserve the exact questions presented to the student at the time of the examination.

---

# 32. Submissions

Example:

```text
submissions/{submissionId}

examId
studentId
recordingUrl
answers
submittedAt
createdAt
```

The student's `answers` are linked to the selected questions of that examination in `exam_questions`.

`submittedAt` records the time the examination was submitted. `submissions` does not hold the score; `theoryScore` is stored in `evaluations`.

The original student submission should remain preserved.

---

# 33. Evaluations

Example:

```text
evaluations/{evaluationId}

examId
supervisorId
recitationScore
theoryScore
finalScore
result
feedback
status
reviewedAt
approvedAt
```

`status` expresses the review and approval state of the evaluation:

```text
pending
approved
```

`result` is separate from `status` and depends on the final score:

```text
passed   (Final Score >= 70)
failed   (Final Score < 70)
```

The system creates the `evaluations` record after the student submits the examination.

* When the record is created, `theoryScore` is already calculated automatically (out of 20), while `recitationScore` is still waiting for the supervisor's review.
* The supervisor is allowed to enter `recitationScore` only (out of 80), within the supervisor's permissions. The supervisor does not write or modify `theoryScore`.
* `finalScore` is calculated from `recitationScore` (80) + `theoryScore` (20) after the recitation score becomes available.
* The student is not allowed to write to or modify `evaluations`.

The `supervisorId` field:

* When the `evaluations` record is created after the student submits the examination, `supervisorId = null`.
* When the supervisor reviews the recitation and enters `recitationScore`, the system records the `supervisorId` of the supervisor who performed the review.
* `supervisorId` represents the supervisor who actually performed the evaluation, not necessarily the supervisor assigned to the square beforehand.

---

# 34. Certificates

Example:

```text
certificates/{certificateId}

studentId
examId
courseId
certificateNumber
finalScore
issuedAt
fileUrl
```

---

# 35. Notifications

Example:

```text
notifications/{notificationId}

userId
title
body
type
relatedId
isRead
createdAt
```

---

# 36. Firebase Storage

Storage should use organized paths.

Example:

```text
profile_images/{uid}/
exam_recordings/{examId}/
certificates/{certificateId}/
```

Access must be controlled using Firebase Security Rules.

Students should not be able to access recordings belonging to unrelated students.

---

# 37. Firebase Security

Security is a core requirement.

Firestore and Storage security rules must enforce:

* User authentication.
* Role-based access.
* Geographic/organizational restrictions.
* Student ownership restrictions.
* Supervisor assignment restrictions.
* Protection of evaluation records.
* Protection of question-bank answers.
* Protection of administrative data.

Exception to user authentication — reading the mosque list during registration:

* Reading the list of active mosques only (`isActive == true`) is allowed before sign-in, because the student needs to choose the mosque during registration.

The client application must not be considered the only security layer.

---

# 38. Flutter Architecture

The application will use a feature-based architecture.

Main structure:

```text
lib/
│
├── core/
│   ├── theme/
│   ├── constants/
│   ├── widgets/
│   ├── services/
│   └── utils/
│
├── features/
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── student/
│   ├── exams/
│   ├── courses/
│   ├── questions/
│   ├── supervisor/
│   ├── region/
│   ├── admin/
│   ├── certificates/
│   └── notifications/
│
├── router/
│
└── main.dart
```

Features that contain significant business logic should use:

```text
data/
domain/
presentation/
```

Presentation should contain:

```text
pages/
widgets/
```

The architecture should avoid putting business logic directly inside UI widgets.

---

# 39. Core Structure

The initial core structure is:

```text
core/
│
├── theme/
│   ├── app_colors.dart
│   ├── app_theme.dart
│   └── app_text_styles.dart
│
├── constants/
│   ├── app_constants.dart
│   ├── firebase_collections.dart
│   └── app_assets.dart
│
├── widgets/
│   ├── app_button.dart
│   ├── app_text_field.dart
│   └── ...
│
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   └── notification_service.dart
│
└── utils/
    ├── validators.dart
    └── helpers.dart
```

Only reusable and genuinely shared components should be placed in `core`.

Feature-specific components must remain inside their feature.

---

# 40. Feature Structure

A feature may use:

```text
feature_name/
│
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── pages/
    ├── widgets/
    └── state/
```

Not every simple feature must contain unnecessary layers.

Architecture should remain clean without creating unnecessary files.

---

# 41. State Management

The project will use:

```text
flutter_bloc
```

State management will use both Cubit and Bloc depending on the complexity of the feature.

Cubit should be used for relatively simple state management.

Bloc should be used for complex event-driven flows where explicit events and state transitions are beneficial.

Examples of state management components may include:

```text
AuthCubit
ExamCubit
RecordingCubit
QuestionsCubit
SupervisorCubit
CertificateCubit
NotificationCubit
```

Not every feature requires its own Cubit or Bloc.

State management must remain consistent throughout the project.

Do not introduce another state-management package without explicit approval.

Phase 1 must use flutter_bloc and must not mix multiple state-management solutions unnecessarily.

---

# 42. Routing

The project should have centralized routing, implemented with `go_router`.

Structure:

```text
router/
├── app_router.dart
└── route_names.dart
```

Routes should support:

* Splash
* Onboarding
* Authentication
* Student screens
* Supervisor screens
* Region screens
* Admin screens

Routing must respect authentication state and user role.

---

# 43. Theme and Localization

The application UI is Arabic and uses RTL.

Requirements:

* Arabic language.
* RTL layout.
* Consistent typography.
* Centralized colors.
* Centralized text styles.
* Reusable components.
* Responsive layout.

Hard-coded styling should be minimized.

---

# 44. UI / Figma

The application UI should follow the approved Figma design.

Figma is the visual source of truth for:

* Colors.
* Typography.
* Spacing.
* Components.
* Buttons.
* Cards.
* Navigation.
* Layout.
* Icons.
* Visual hierarchy.

Claude Code should inspect the Figma design through the connected Figma MCP before implementing the UI.

Claude must not invent alternative UI designs when an approved Figma design exists.

If Figma conflicts with the written project specification, the conflict must be reported before implementation.

---

# 45. Main Student Interfaces

The student application should include interfaces such as:

1. Splash
2. Onboarding
3. Login
4. Student Registration
5. Home
6. Profile
7. Courses
8. Course Details
9. Start Examination
10. Quran Recitation / Recording
11. Theory Questions
12. Review Submission
13. Submission Status
14. Result
15. Certificate
16. Notifications

In Phase 1, the student can create their own account through Student Registration.

The student does not choose a role during registration. The role is assigned automatically to `student`.

During registration, the student chooses the mosque from the list of available mosques. The student does not choose the region or the square; the system derives them automatically from the mosque.

The `region_officer`, `square_supervisor`, and `general_admin` accounts are not created through public registration. The `region_officer` and `square_supervisor` accounts are created by the General Admin, and are managed by the administrative authorities according to the approved permissions.

The final interface count may be adjusted according to the approved Figma design.

---

# 46. Supervisor Interfaces

The supervisor section should support:

* Supervisor Dashboard
* Pending Examinations
* Examination Details
* Student Information
* Recitation Review
* Theory Answers
* Evaluation
* Final Result
* Student History
* Notifications

---

# 47. Region Officer Interfaces

The Region Officer section should support:

* Region Dashboard
* Squares
* Supervisors
* Mosques
* Students
* Examination Statistics
* Notifications

---

# 48. General Admin Interfaces

The General Admin section should support:

* Admin Dashboard
* Regions
* Region Officers
* Squares
* Supervisors
* Mosques
* Students
* Courses
* Tajweed Rules
* Question Bank
* Examinations
* Certificates
* Notifications
* System Statistics

---

# 49. Current Phase 1 Limitations

Phase 1 intentionally does NOT include:

* Automatic Tajweed AI analysis.
* Custom AI model.
* Automatic pronunciation error detection.
* Automatic Tajweed rule detection.
* Advanced AI recitation scoring.

These are Future Work only (Phase 2 and Phase 3) and are not implemented now.

---

# 50. Future Work — Phase 2: Ready AI API

Phase 2 is Future Work only. No part of it is implemented now.

After successful Phase 1 testing, the system may integrate a ready-made AI/API service for recitation analysis.

Target courses:

```text
تمهيدية
تأهيلية
```

The AI should assist with:

* Recitation analysis.
* Tajweed-related evaluation.
* Automated scoring assistance.

The advanced courses:

```text
عليا
السند
```

may remain under supervisor review.

The exact AI provider will be selected later after technical evaluation.

---

# 51. Future Work — Phase 3: Custom AI

Phase 3 is Future Work only. No part of it is implemented now.

The long-term goal is a custom Quran recitation and Tajweed analysis model.

Potential training data may include approved recitations from qualified reciters.

The system may eventually analyze:

* Pronunciation.
* Tajweed rules.
* Madd.
* Ghunnah.
* Noon Sakinah and Tanween.
* Meem Sakinah.
* Qalqalah.
* Waqf and Ibtida.
* Saktah.
* Other Tajweed rules.

This phase is outside the graduation project's Phase 1.

---

# 52. Multi-Institution Support

The system should be designed so it can later support multiple Quran institutions.

Possible hierarchy:

```text
Institution
   ↓
Region
   ↓
Square
   ↓
Mosque
   ↓
Students
```

The current Phase 1 may operate with one initial organization while keeping the architecture extensible.

---

# 53. Testing

Before deployment, Phase 1 should undergo approximately two months of testing.

Testing should verify:

* Authentication.
* Permissions.
* Examination workflow.
* Audio recording.
* Audio upload.
* Question submission.
* Supervisor review.
* Score calculation.
* Certificate generation.
* Notifications.
* Security rules.
* Data consistency.

---

# 54. Development Rules

Claude Code must follow these rules:

1. Read `PROJECT_SPEC.md` before implementing major features.
2. Do not invent business requirements.
3. Do not change the architecture without approval.
4. Do not add AI to Phase 1.
5. Do not add unnecessary packages.
6. Do not duplicate business logic.
7. Keep UI separate from business logic.
8. Follow the Figma design.
9. Preserve Arabic RTL support.
10. Respect Firebase security requirements.
11. Implement features incrementally.
12. Test each major feature before moving to the next.
13. Do not delete existing functionality without approval.
14. Before making large architectural changes, explain the reason and request approval.
15. Keep the project maintainable and scalable.

---

# 55. Implementation Order

The implementation should follow this general order:

```text
1. Project Analysis
2. Architecture Confirmation
3. Folder Structure
4. Firebase Configuration
5. Theme / RTL / Core
6. Authentication
7. Role-Based Routing
8. Student Module
9. Examination System
10. Recording
11. Theory Questions
12. Submission
13. Supervisor Review: Recitation Score, Theory Score, Final Score, Evaluation Approval
14. Notifications, Certificates, Region Officer Module, General Admin Module, Reports, Account and Role Management
15. Security Rules
16. Testing
17. Phase 1 Deployment
```

AI must not be implemented before Phase 1 is completed and tested.

---

# 56. Source of Truth

The following priority should be used when making implementation decisions:

```text
1. Approved Project Decisions
2. PROJECT_SPEC.md
3. Approved Figma Design
4. Firebase Security Requirements
5. Existing Project Architecture
6. Developer Implementation Details
```

When there is a conflict between these sources, Claude must stop and ask for clarification rather than silently choosing a solution.

---

# 57. Current Development State

Current state:

```text
Project initialized.
PROJECT_SPEC.md created.
Phase 1 decisions approved (see "Approved Phase 1 Decisions").
Phase 2 and Phase 3 are Future Work only.
Project analysis completed (Implementation Order step 1).
Architecture confirmed (Implementation Order step 2).
Implementation Order steps 3-13 implemented.
AI is not part of Phase 1.
Figma MCP is connected to Claude Code.
```

Open items: the approved Quran text and Mushaf font have not been added, and Cloud Functions are deferred (see Approved Phase 1 Decisions 14 and 19).

Recording (step 10): the recitation is uploaded to `exam_recordings/{examId}/recitation.m4a`, and re-recording is allowed while the examination is `in_progress`. `recordingUrl` is written to `submissions` in step 12. `storage.rules` is not deployed yet, and recording has not been tested on a device.

Theory Questions (step 11): the ten questions are read from `exam_questions` and shown one per screen, opened from the examination screen once the recitation is uploaded. The answers are kept in memory until submission and are lost if the app is closed before it. The whole question text is shown in one style, because `question` is a single string.

Submission (step 12): the student reviews the recording status and the ten answers, then submits. One batch creates `submissions/{examId}` and moves the examination from `in_progress` to `pending_review` with `submittedAt`. `recordingUrl` holds the Storage path of the recording, not a download link. Each item of `answers` is `{order, questionId, answer}`. The review and confirmation screens have no Figma frame and follow the style of the questions screen. Deferred to step 13: creating the `evaluations` record and calculating `theoryScore`, because the student can neither read `question_answers` nor write `evaluations` and Cloud Functions are deferred. The updated `firestore.rules` are not deployed yet, and submission has not been tested against Firebase.

Supervisor Review (step 13): the supervisor's home lists the examinations of the square that await review, oldest submission first. Opening one shows the student, the course, the segment reference, the recitation (downloaded from Storage, then played) and the ten answers, each marked against its correct answer. The supervisor enters the recitation score out of 80; the theory score out of 20 is calculated from the student's answers and `question_answers` (two marks per question), and the final score out of 100 and the result (pass mark 70) are shown. Approving the result writes one batch: it creates `evaluations/{examId}` with `status = approved` and moves the examination to `approved` with `reviewedAt` and `approvedAt`. Differences from section 33, by decision: the `evaluations` record is created when the supervisor approves, not when the student submits, so no `pending` evaluation exists; `feedback` is stored as null because no feedback field is shown yet. No examination is moved to `under_review`. Interim limit: the theory score is calculated on the supervisor's device, so an active supervisor can read `question_answers` one document at a time, and the security rules check the range and the arithmetic of the scores but not that `theoryScore` matches the answers. The supervisor screens were built in the style of the existing screens, without inspecting Figma, because the Figma MCP call limit was reached; they must be compared with the approved frames later. Not built: Supervisor Dashboard statistics, Student History, the student's result screen. The updated `firestore.rules` and `storage.rules` are not deployed yet, and the module has not been tested against Firebase or on a device.

The next step is Implementation Order step 14: Notifications, Certificates, Region Officer Module, General Admin Module, Reports, Account and Role Management.
