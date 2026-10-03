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

  /// The current recording is the one in Storage.
  uploaded,
}

class RecordingState {
  const RecordingState({
    this.status = RecordingStatus.idle,
    this.elapsed = Duration.zero,
    this.hasUploaded = false,
    this.uploadProgress = 0,
    this.errorMessage,
  });

  final RecordingStatus status;

  /// The length of the current recording.
  final Duration elapsed;

  /// Whether Storage holds a recording of the examination. It stays true
  /// while a newer recording waits on the device to replace it.
  final bool hasUploaded;

  /// The uploaded share of the recording, from 0 to 1, while uploading.
  final double uploadProgress;

  /// Set only on the state emitted by a failed action.
  final String? errorMessage;

  RecordingState copyWith({
    RecordingStatus? status,
    Duration? elapsed,
    bool? hasUploaded,
    double? uploadProgress,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      hasUploaded: hasUploaded ?? this.hasUploaded,
      uploadProgress: uploadProgress ?? this.uploadProgress,
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
        emit(
          const RecordingState(
            status: RecordingStatus.uploaded,
            hasUploaded: true,
          ),
        );
      }
    } on AppFailure {
      // The student can still record; uploading replaces any earlier file.
    }
  }

  /// Starts a new recording, replacing the one on the device. Nothing is
  /// uploaded: a recording in Storage stays until [upload] replaces it.
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
    emit(
      RecordingState(
        status: RecordingStatus.recording,
        hasUploaded: state.hasUploaded,
      ),
    );
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => emit(state.copyWith(elapsed: _stopwatch.elapsed)),
    );
  }

  /// Stops recording and keeps the file on the device. Nothing is uploaded.
  Future<void> stop() async {
    if (state.status != RecordingStatus.recording) return;
    _ticker?.cancel();
    _stopwatch.stop();
    try {
      final path = await _recorder.stop();
      if (path == null) {
        emit(_withoutLocal('لم يُحفظ التسجيل. أعد المحاولة.'));
        return;
      }
      _filePath = path;
      emit(
        RecordingState(
          status: RecordingStatus.recorded,
          elapsed: _stopwatch.elapsed,
          hasUploaded: state.hasUploaded,
        ),
      );
    } on AppFailure catch (failure) {
      emit(_withoutLocal(failure.message));
    }
  }

  /// The state once the recording on the device is lost: back to the
  /// recording in Storage when there is one.
  RecordingState _withoutLocal(String errorMessage) => RecordingState(
    status: state.hasUploaded ? RecordingStatus.uploaded : RecordingStatus.idle,
    hasUploaded: state.hasUploaded,
    errorMessage: errorMessage,
  );

  /// Plays the recording kept on the device.
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

  /// Uploads the recording kept on the device, replacing the one in Storage.
  /// The examination is not submitted.
  Future<void> upload() async {
    final path = _filePath;
    if (state.status != RecordingStatus.recorded || path == null) return;
    emit(state.copyWith(status: RecordingStatus.uploading, uploadProgress: 0));
    try {
      await _repository.uploadRecording(
        examId: _examId,
        filePath: path,
        onProgress: (progress) {
          if (isClosed || state.status != RecordingStatus.uploading) return;
          emit(state.copyWith(uploadProgress: progress.clamp(0, 1).toDouble()));
        },
      );
      if (isClosed) return;
      emit(state.copyWith(status: RecordingStatus.uploaded, hasUploaded: true));
    } on AppFailure catch (failure) {
      if (isClosed) return;
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
