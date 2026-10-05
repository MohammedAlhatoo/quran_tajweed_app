import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/entities/tajweed_rule.dart';
import '../../../courses/domain/repositories/courses_repository.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/exam_segment.dart';
import '../../../exams/domain/entities/submission.dart';
import '../../../exams/domain/repositories/exams_repository.dart';
import '../../../questions/domain/entities/exam_question.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/repositories/review_repository.dart';

sealed class ExamReviewState {
  const ExamReviewState();
}

class ExamReviewLoading extends ExamReviewState {
  const ExamReviewLoading();
}

class ExamReviewLoaded extends ExamReviewState {
  const ExamReviewLoaded({
    required this.exam,
    required this.course,
    required this.segment,
    required this.student,
    required this.submission,
    required this.questions,
    required this.theoryScore,
    this.correctAnswers = const {},
    this.rules = const [],
    this.ayahs = const [],
  });

  final Exam exam;

  /// Null when the course is no longer available.
  final Course? course;
  final ExamSegment segment;

  /// Null when the student's account cannot be read, for example because the
  /// student's mosque has moved to another square since the examination.
  final AppUser? student;
  final Submission submission;
  final List<ExamQuestion> questions;

  /// The theory score out of 20, saved when the student submitted the
  /// examination. Null when none is saved; the result cannot be approved
  /// then.
  final int? theoryScore;

  /// The correct answer of each question, keyed by the order of the question,
  /// from the answer key of the examination. Empty when it has none.
  final Map<int, String> correctAnswers;

  /// The Tajweed rules an error can be recorded against. Empty when they
  /// cannot be read or none are stored.
  final List<TajweedRule> rules;

  /// The ayahs of the segment, in order, from the Quran data in the app. Empty
  /// when the text cannot be read.
  final List<QuranAyah> ayahs;

  /// The correct answer of [question], or null when it is not stored.
  String? correctAnswerTo(ExamQuestion question) =>
      correctAnswers[question.order];

  /// The student's answer to [question], or null when there is none.
  String? answerTo(ExamQuestion question) {
    for (final answer in submission.answers) {
      if (answer.order == question.order) return answer.answer;
    }
    return null;
  }
}

class ExamReviewError extends ExamReviewState {
  const ExamReviewError(this.message);

  final String message;
}

/// Loads everything a supervisor reviews in one submitted examination: the
/// student, the course, the Quran segment, the submission, the questions with
/// their correct answers, and the saved theory score.
class ExamReviewCubit extends Cubit<ExamReviewState> {
  ExamReviewCubit({
    required this._reviews,
    required this._exams,
    required this._courses,
    required this._quran,
    required this._examId,
  }) : super(const ExamReviewLoading());

  final ReviewRepository _reviews;
  final ExamsRepository _exams;
  final CoursesRepository _courses;
  final QuranRepository _quran;
  final String _examId;

  Future<void> load() async {
    emit(const ExamReviewLoading());
    try {
      final exam = await _exams.fetchExam(_examId);
      if (exam == null) {
        emit(const ExamReviewError('هذا الاختبار غير موجود.'));
        return;
      }
      final segment = await _exams.fetchSegment(exam.segmentId);
      if (segment == null) {
        emit(const ExamReviewError('مقطع هذا الاختبار غير متاح.'));
        return;
      }
      final student = await _fetchStudent(exam.studentId);
      final submission = await _reviews.fetchSubmission(_examId);
      if (submission == null) {
        emit(const ExamReviewError('لم يُرسل هذا الاختبار بعد.'));
        return;
      }
      emit(
        ExamReviewLoaded(
          exam: exam,
          course: await _courses.fetchCourse(exam.courseId),
          segment: segment,
          student: student,
          submission: submission,
          questions: await _reviews.fetchExamQuestions(_examId),
          theoryScore: await _reviews.fetchTheoryScore(_examId),
          correctAnswers: await _reviews.fetchAnswerKey(_examId),
          rules: await _fetchRules(),
          ayahs: await _fetchAyahs(segment),
        ),
      );
    } on AppFailure catch (failure) {
      emit(ExamReviewError(failure.message));
    }
  }

  /// The recitation is reviewed against the reference of the segment when its
  /// text cannot be read, so the review does not depend on the text.
  Future<List<QuranAyah>> _fetchAyahs(ExamSegment segment) async {
    try {
      return await _quran.ayahsOf(
        segment.surah,
        segment.ayahFrom,
        segment.ayahTo,
      );
    } on QuranDataException {
      return const [];
    }
  }

  /// The result can be approved without detailed errors, so the review does
  /// not depend on the rules.
  Future<List<TajweedRule>> _fetchRules() async {
    try {
      return await _reviews.fetchTajweedRules();
    } on AppFailure {
      return const [];
    }
  }

  /// The examination stays reviewable by the supervisor of the square it was
  /// started in, even when the student's account is no longer in that square
  /// and so can no longer be read.
  Future<AppUser?> _fetchStudent(String studentId) async {
    try {
      return await _reviews.fetchStudent(studentId);
    } on AppFailure {
      return null;
    }
  }
}
