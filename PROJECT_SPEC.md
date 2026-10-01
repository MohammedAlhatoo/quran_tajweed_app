# Quran Tajweed Testing Platform

## Project Specification

**Project Type:** Graduation Project
**Technology:** Flutter + Firebase
**Qur'an Standard:** Hafs 'an Asim
**Mushaf:** Madinah Mushaf — 604 Pages
**Current Development Phase:** MVP — Manual Supervisor Evaluation
**AI:** Not implemented in MVP

---

# 1. Project Overview

The project is an interactive digital platform for testing Quran recitation and Tajweed.

The platform allows Quran students to complete recitation and theoretical Tajweed examinations remotely instead of requiring all examinations to take place physically at Quran centers or mosques.

The current MVP focuses on manual evaluation by approved supervisors.

The system will later support AI-assisted recitation analysis through external AI APIs and eventually a custom Tajweed analysis model.

---

# 2. Main Problem

Due to difficulties that may prevent students and supervisors from conducting Quran and Tajweed examinations in person, especially in areas where access to Quran centers and mosques may be disrupted, there is a need for a digital examination platform.

The platform allows:

* Students to submit Quran recitation recordings remotely.
* Students to answer theoretical Tajweed questions.
* Supervisors to review submissions remotely.
* Supervisors to evaluate recitation and answers.
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

# 4. MVP Scope

The current graduation-project MVP will NOT use AI.

The MVP will use:

* Flutter
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* Firebase Cloud Messaging
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
* Managing approved supervisors according to permissions.
* Viewing mosques.
* Viewing students.
* Viewing examination statistics.
* Monitoring examination activity.

The Region Officer must not access unrelated regions.

---

## 5.3 Square Supervisor

A Square Supervisor is responsible for approximately 4–5 mosques.

Responsibilities include:

* Viewing assigned mosques.
* Viewing assigned students.
* Reviewing submitted examinations.
* Listening to recitation recordings.
* Reviewing theoretical answers.
* Entering recitation evaluation.
* Entering question evaluation.
* Approving final examination results.
* Viewing student examination history.

A supervisor must only access students and examinations belonging to the supervisor's assigned square.

---

## 5.4 Student

Students can:

* Sign in.
* View their profile.
* View their assigned mosque.
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

Role-based access control must be implemented.

Routing and Firebase security rules must respect the user's role.

---

# 7. Quran Standard

The platform uses:

* Riwayah: Hafs 'an Asim
* Mushaf: Madinah Mushaf
* Total pages: 604

The Quran content must be handled carefully and consistently.

The application should not arbitrarily modify Quran text.

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
Status = Pending Review
   ↓
Supervisor Reviews
   ↓
Supervisor Evaluates Recitation
   ↓
Supervisor Evaluates Questions
   ↓
System Calculates Final Score
   ↓
Supervisor Approves Result
   ↓
Student Receives Result
   ↓
Certificate Generated
```

---

# 11. Quran Segment Selection

The MVP should use a structured Quran segment database.

The selected segment should be appropriate for the student's course.

The selection should consider Tajweed rule density.

The goal is to select Quran segments containing relevant Tajweed rules suitable for the examination level.

The segment may be approximately 5–7 lines or an appropriate portion of a page.

The exact segment selection logic should be implemented as a service rather than inside the UI.

Future versions may introduce more advanced randomization and AI-assisted selection.

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
Recitation Score + Theory Score = Final Score / 100
```

The system should calculate the final score automatically.

The supervisor may enter or adjust the evaluation according to the examination workflow and permissions.

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
rejected
```

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
6. Enter recitation score.
7. Enter theory score.
8. Add notes or feedback.
9. Review the calculated final score.
10. Approve or reject the result.

Evaluation records should be stored separately from the student's original submission where appropriate.

---

# 17. Certificates

After the supervisor approves a successful examination:

* A certificate record should be created.
* The certificate should be associated with the student.
* The certificate should be associated with the course.
* The certificate should include the final result.
* The certificate should have a unique identifier.
* The certificate should be viewable by the student.
* The certificate may later be downloadable or printable.

---

# 18. Notifications

Firebase Cloud Messaging should be used for important notifications.

Examples:

* Examination submitted.
* Examination under review.
* Examination approved.
* Examination rejected.
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
Firebase Cloud Messaging
```

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

---

# 21. Firestore Collections

The initial Firestore structure is:

```text
users
regions
squares
mosques
courses
course_rules
exams
exam_segments
questions
question_bank
submissions
evaluations
certificates
notifications
```

The exact document fields should be defined before implementation.

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

* Student → mosqueId
* Square Supervisor → squareId
* Region Officer → regionId
* General Admin → no geographic restriction

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
ruleName
description
weight
createdAt
```

This allows each course to define its own Tajweed rule coverage.

---

# 28. Exams Collection

Example:

```text
exams/{examId}

studentId
courseId
segmentId
status
startedAt
submittedAt
reviewedAt
approvedAt
createdAt
updatedAt
```

---

# 29. Exam Segments

Example:

```text
exam_segments/{segmentId}

surah
ayahFrom
ayahTo
page
text
ruleIds
courseIds
difficulty
ruleDensity
isActive
createdAt
```

The actual Quran data must be handled carefully and should not be duplicated unnecessarily.

---

# 30. Question Bank

The question bank stores reusable questions.

Example:

```text
question_bank/{questionId}

courseId
ruleId
type
question
options
correctAnswer
difficulty
isActive
createdAt
updatedAt
```

The correct answer must not be exposed to the student client unnecessarily.

---

# 31. Exam Questions

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
feedback
status
reviewedAt
approvedAt
```

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

# 41. State Management

The project will use:

flutter_bloc

State management will use both Cubit and Bloc depending on the complexity of the feature.

Cubit should be used for relatively simple state management.

Bloc should be used for complex event-driven flows where explicit events and state transitions are beneficial.

Examples of state management components may include:

AuthCubit
ExamCubit
RecordingCubit
QuestionsCubit
SupervisorCubit
CertificateCubit
NotificationCubit

Not every feature requires its own Cubit or Bloc.

State management must remain consistent throughout the project.

Do not introduce another state-management package without explicit approval.

The MVP must use flutter_bloc and must not mix multiple state-management solutions unnecessarily.

---

# 42. Routing

The project should have centralized routing.

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
4. Home
5. Profile
6. Courses
7. Course Details
8. Start Examination
9. Quran Recitation / Recording
10. Theory Questions
11. Review Submission
12. Submission Status
13. Result
14. Certificate
15. Notifications

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

# 49. Current MVP Limitations

The MVP intentionally does NOT include:

* Automatic Tajweed AI analysis.
* Custom AI model.
* Automatic pronunciation error detection.
* Automatic Tajweed rule detection.
* Advanced AI recitation scoring.

These are future development phases.

---

# 50. Development Phase 2 — Ready AI API

After successful MVP testing, the system may integrate a ready-made AI/API service for recitation analysis.

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

# 51. Development Phase 3 — Custom AI

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

This phase is outside the graduation MVP.

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

The current MVP may operate with one initial organization while keeping the architecture extensible.

---

# 53. Testing

Before deployment, the MVP should undergo approximately two months of testing.

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
4. Do not add AI to the MVP.
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
13. Supervisor Module
14. Evaluation
15. Score Calculation
16. Certificates
17. Notifications
18. Region Officer Module
19. General Admin Module
20. Security Rules
21. Testing
22. MVP Deployment
```

AI must not be implemented before the MVP is completed and tested.

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
Implementation has not started.
AI is not part of MVP.
Figma MCP is connected to Claude Code.
```

The next step is to review this specification and confirm the architecture before creating the production folder structure or implementing features.
