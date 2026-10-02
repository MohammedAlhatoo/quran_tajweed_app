import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../questions/domain/entities/exam_question.dart';
import '../../domain/entities/submission_answer.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/repositories/submission_repository.dart';

enum SubmissionStatus {
  /// Checking whether the recitation is uploaded.
  checking,
  ready,
  submitting,
  submitted,
}

class SubmissionState {
  const SubmissionState({
    this.status = SubmissionStatus.checking,
    this.hasRecording = false,
    this.errorMessage,
  });

  final SubmissionStatus status;

  /// Whether the recitation recording is uploaded.
  final bool hasRecording;

  /// Set only on the state emitted by a failed action.
  final String? errorMessage;
}

/// Submits one examination: its uploaded recitation and its ten answers.
class SubmissionCubit extends Cubit<SubmissionState> {
  SubmissionCubit({
    required this._submissions,
    required this._recordings,
    required this._examId,
    required this._studentId,
  }) : super(const SubmissionState());

  final SubmissionRepository _submissions;
  final RecordingRepository _recordings;
  final String _examId;
  final String _studentId;

  /// Checks whether the recitation is uploaded.
  Future<void> load() async {
    emit(const SubmissionState());
    try {
      final hasRecording = await _recordings.hasRecording(_examId);
      emit(
        SubmissionState(
          status: SubmissionStatus.ready,
          hasRecording: hasRecording,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        SubmissionState(
          status: SubmissionStatus.ready,
          errorMessage: failure.message,
        ),
      );
    }
  }

  /// Submits the examination. [chosen] holds the chosen option of each of
  /// [questions], keyed by the ID of its `exam_questions` record.
  Future<void> submit({
    required List<ExamQuestion> questions,
    required Map<String, String> chosen,
  }) async {
    if (state.status != SubmissionStatus.ready) return;
    final answers = SubmissionAnswer.listFrom(questions, chosen);
    if (answers == null || answers.isEmpty) {
      emit(_ready(errorMessage: 'أجب عن جميع الأسئلة قبل الإرسال.'));
      return;
    }

    emit(
      SubmissionState(
        status: SubmissionStatus.submitting,
        hasRecording: state.hasRecording,
      ),
    );
    try {
      if (!await _recordings.hasRecording(_examId)) {
        emit(
          const SubmissionState(
            status: SubmissionStatus.ready,
            errorMessage: 'ارفع تسجيل التلاوة قبل إرسال الاختبار.',
          ),
        );
        return;
      }
      await _submissions.submitExam(
        examId: _examId,
        studentId: _studentId,
        answers: answers,
      );
      emit(
        const SubmissionState(
          status: SubmissionStatus.submitted,
          hasRecording: true,
        ),
      );
    } on AppFailure catch (failure) {
      emit(_ready(errorMessage: failure.message));
    }
  }

  SubmissionState _ready({String? errorMessage}) => SubmissionState(
    status: SubmissionStatus.ready,
    hasRecording: state.hasRecording,
    errorMessage: errorMessage,
  );
}
