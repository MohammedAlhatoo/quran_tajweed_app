import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../exams/domain/services/recitation_audio.dart';
import '../../domain/repositories/review_repository.dart';

enum PlaybackStatus {
  idle,

  /// Downloading the recording before the first playback.
  loading,
  playing,
}

class PlaybackState {
  const PlaybackState({this.status = PlaybackStatus.idle, this.errorMessage});

  final PlaybackStatus status;

  /// Set only on the state emitted by a failed action.
  final String? errorMessage;
}

/// Lets a supervisor listen to the recitation of one examination.
class RecitationPlaybackCubit extends Cubit<PlaybackState> {
  RecitationPlaybackCubit({
    required this._repository,
    required this._player,
    required this._examId,
  }) : super(const PlaybackState());

  final ReviewRepository _repository;
  final RecitationPlayer _player;
  final String _examId;

  /// The downloaded recording, kept for later playbacks.
  String? _filePath;

  /// Plays the recording stored at [recordingPath]. It is downloaded the
  /// first time.
  Future<void> play(String recordingPath) async {
    if (state.status != PlaybackStatus.idle) return;
    String? error;
    try {
      var path = _filePath;
      if (path == null) {
        emit(const PlaybackState(status: PlaybackStatus.loading));
        path = _filePath = await _repository.downloadRecording(
          examId: _examId,
          recordingPath: recordingPath,
        );
        if (isClosed) return;
      }
      emit(const PlaybackState(status: PlaybackStatus.playing));
      await _player.play(path);
    } on AppFailure catch (failure) {
      error = failure.message;
    }
    if (!isClosed) emit(PlaybackState(errorMessage: error));
  }

  Future<void> stop() async {
    if (state.status != PlaybackStatus.playing) return;
    await _player.stop();
  }

  @override
  Future<void> close() async {
    await _player.dispose();
    return super.close();
  }
}
