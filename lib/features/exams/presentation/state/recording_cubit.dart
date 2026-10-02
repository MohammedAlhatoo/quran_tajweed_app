import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/services/recitation_audio.dart';

enum RecordingStatus {
  /// Nothing recorded yet.
  idle,
  recording,

  /// Recorded on the device and not uploaded yet.
  recorded,
  playing,
  uploading,
  uploaded,
}

class RecordingState {
  const RecordingState({
    this.status = RecordingStatus.idle,
    this.elapsed = Duration.zero,
    this.errorMessage,
  });

  final RecordingStatus status;

  /// The length of the current recording.
  final Duration elapsed;

  /// Set only on the state emitted by a failed action.
  final String? errorMessage;

  RecordingState copyWith({
    RecordingStatus? status,
    Duration? elapsed,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      errorMessage: errorMessage,
    );
  }
}

/// Records, plays back and uploads the recitation of one examination.
class RecordingCubit extends Cubit<RecordingState> {
  RecordingCubit({
    required this._repository,
    required this._recorder,
    required this._player,
    required this._examId,
  }) : super(const RecordingState());

  final RecordingRepository _repository;
  final RecitationRecorder _recorder;
  final RecitationPlayer _player;
  final String _examId;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  String? _filePath;

  /// Shows a recording uploaded in an earlier visit to the examination.
  Future<void> load() async {
    try {
      final uploaded = await _repository.hasRecording(_examId);
      if (uploaded && !isClosed && state.status == RecordingStatus.idle) {
        emit(const RecordingState(status: RecordingStatus.uploaded));
      }
    } on AppFailure {
      // The student can still record; uploading replaces any earlier file.
    }
  }

  /// Starts a new recording. An earlier recording is replaced.
  Future<void> start() async {
    const startable = [
      RecordingStatus.idle,
      RecordingStatus.recorded,
      RecordingStatus.uploaded,
    ];
    if (!startable.contains(state.status)) return;
    try {
      if (!await _recorder.hasPermission()) {
        emit(
          state.copyWith(
            errorMessage: 'اسمح للتطبيق باستخدام الميكروفون لتسجيل التلاوة.',
          ),
        );
        return;
      }
      await _recorder.start();
    } on AppFailure catch (failure) {
      emit(state.copyWith(errorMessage: failure.message));
      return;
    }
    _filePath = null;
    emit(const RecordingState(status: RecordingStatus.recording));
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => emit(state.copyWith(elapsed: _stopwatch.elapsed)),
    );
  }

  Future<void> stop() async {
    if (state.status != RecordingStatus.recording) return;
    _ticker?.cancel();
    _stopwatch.stop();
    try {
      final path = await _recorder.stop();
      if (path == null) {
        emit(const RecordingState(errorMessage: 'لم يُحفظ التسجيل. أعد المحاولة.'));
        return;
      }
      _filePath = path;
      emit(
        RecordingState(
          status: RecordingStatus.recorded,
          elapsed: _stopwatch.elapsed,
        ),
      );
    } on AppFailure catch (failure) {
      emit(RecordingState(errorMessage: failure.message));
    }
  }

  Future<void> play() async {
    final path = _filePath;
    if (state.status != RecordingStatus.recorded || path == null) return;
    emit(state.copyWith(status: RecordingStatus.playing));
    String? error;
    try {
      await _player.play(path);
    } on AppFailure catch (failure) {
      error = failure.message;
    }
    if (isClosed || state.status != RecordingStatus.playing) return;
    emit(state.copyWith(status: RecordingStatus.recorded, errorMessage: error));
  }

  Future<void> stopPlayback() async {
    if (state.status != RecordingStatus.playing) return;
    await _player.stop();
  }

  Future<void> upload() async {
    final path = _filePath;
    if (state.status != RecordingStatus.recorded || path == null) return;
    emit(state.copyWith(status: RecordingStatus.uploading));
    try {
      await _repository.uploadRecording(examId: _examId, filePath: path);
      emit(state.copyWith(status: RecordingStatus.uploaded));
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: RecordingStatus.recorded,
          errorMessage: failure.message,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _recorder.dispose();
    await _player.dispose();
    return super.close();
  }
}
