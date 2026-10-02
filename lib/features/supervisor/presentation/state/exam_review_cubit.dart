import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/repositories/courses_repository.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/exam_segment.dart';
import '../../../exams/domain/entities/submission.dart';
import '../../../exams/domain/repositories/exams_repository.dart';
import '../../../questions/domain/entities/exam_question.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/exam_scoring.dart';

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
    required this.correctAnswers,
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

  /// The correct answer of each question, keyed by the ID of its source
  /// question.
  final Map<String, String> correctAnswers;

  /// The theory score out of 20, or null when it cannot be calculated
  /// because the questions or their correct answers are missing.
  int? get theoryScore => ExamScoring.theoryScore(
    questions: questions,
    answers: submission.answers,
    correctAnswers: correctAnswers,
  );

  /// The correct answer of [question], or null when it is not stored.
  String? correctAnswerTo(ExamQuestion question) =>
      correctAnswers[question.questionId];

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
/// student, the course, the Quran segment, the submission, and the questions
/// with their correct answers.
class ExamReviewCubit extends Cubit<ExamReviewState> {
  ExamReviewCubit({
    required this._reviews,
    required this._exams,
    required this._courses,
    required this._examId,
  }) : super(const ExamReviewLoading());

  final ReviewRepository _reviews;
  final ExamsRepository _exams;
  final CoursesRepository _courses;
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
      final questions = await _reviews.fetchExamQuestions(_examId);
      emit(
        ExamReviewLoaded(
          exam: exam,
          course: await _courses.fetchCourse(exam.courseId),
          segment: segment,
          student: student,
          submission: submission,
          questions: questions,
          correctAnswers: await _reviews.fetchCorrectAnswers([
            for (final question in questions) question.questionId,
          ]),
        ),
      );
    } on AppFailure catch (failure) {
      emit(ExamReviewError(failure.message));
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
