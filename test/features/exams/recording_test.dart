import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/recording_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/recitation_audio.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/recording_cubit.dart';

class _FakeRecordingRepository implements RecordingRepository {
  AppFailure? failure;
  bool uploaded = false;
  String? uploadedPath;
  int uploads = 0;

  /// Reported to the caller before the upload completes.
  List<double> progress = const [];

  @override
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
    void Function(double progress)? onProgress,
  }) async {
    if (failure case final failure?) throw failure;
    progress.forEach(onProgress ?? (_) {});
    uploadedPath = filePath;
    uploads++;
    uploaded = true;
  }

  @override
  Future<bool> hasRecording(String examId) async {
    if (failure case final failure?) throw failure;
    return uploaded;
  }
}

class _FakeRecorder implements RecitationRecorder {
  bool permission = true;
  String? path = 'recitation.m4a';
  int starts = 0;
  AppFailure? startFailure;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async {
    if (startFailure case final failure?) throw failure;
    starts++;
  }

  @override
  Future<String?> stop() async => path;

  @override
  Future<void> dispose() async {}
}

class _FakePlayer implements RecitationPlayer {
  Completer<void>? _playback;
  final List<String> played = [];

  @override
  Future<void> play(String filePath) {
    played.add(filePath);
    return (_playback = Completer<void>()).future;
  }

  @override
  Future<void> stop() async => _playback?.complete();

  @override
  Future<void> dispose() async {}
}

void main() {
  late _FakeRecordingRepository repository;
  late _FakeRecorder recorder;
  late _FakePlayer player;
  late RecordingCubit cubit;

  setUp(() {
    repository = _FakeRecordingRepository();
    recorder = _FakeRecorder();
    player = _FakePlayer();
    cubit = RecordingCubit(
      repository: repository,
      recorder: recorder,
      player: player,
      examId: 'exam-1',
    );
  });

  tearDown(() => cubit.close());

  Future<void> record() async {
    await cubit.start();
    await cubit.stop();
  }

  test('load shows a recording uploaded earlier', () async {
    repository.uploaded = true;

    await cubit.load();

    expect(cubit.state.status, RecordingStatus.uploaded);
  });

  test('load stays idle when the check fails', () async {
    repository.failure = const AppFailure('تعذّر الاتصال.');

    await cubit.load();

    expect(cubit.state.status, RecordingStatus.idle);
    expect(cubit.state.errorMessage, isNull);
  });

  test('start then stop keeps the recording on the device', () async {
    await cubit.start();
    expect(cubit.state.status, RecordingStatus.recording);

    await cubit.stop();
    expect(cubit.state.status, RecordingStatus.recorded);
  });

  test('start without the microphone permission reports it', () async {
    recorder.permission = false;

    await cubit.start();

    expect(cubit.state.status, RecordingStatus.idle);
    expect(cubit.state.errorMessage, isNotNull);
    expect(recorder.starts, 0);
  });

  test('stop without a recorded file returns to idle', () async {
    recorder.path = null;

    await record();

    expect(cubit.state.status, RecordingStatus.idle);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('playback ends back in recorded', () async {
    await record();

    final playing = cubit.play();
    expect(cubit.state.status, RecordingStatus.playing);

    await cubit.stopPlayback();
    await playing;
    expect(cubit.state.status, RecordingStatus.recorded);
  });

  test('upload sends the recorded file', () async {
    await record();

    await cubit.upload();

    expect(cubit.state.status, RecordingStatus.uploaded);
    expect(repository.uploadedPath, 'recitation.m4a');
  });

  test('a failed upload keeps the recording and reports the error', () async {
    await record();
    repository.failure = const AppFailure('تعذّر الاتصال.');

    await cubit.upload();

    expect(cubit.state.status, RecordingStatus.recorded);
    expect(cubit.state.errorMessage, 'تعذّر الاتصال.');
  });

  test('a recording can be replaced after it was uploaded', () async {
    await record();
    await cubit.upload();

    await cubit.start();

    expect(cubit.state.status, RecordingStatus.recording);
    expect(recorder.starts, 2);
  });

  test('upload does nothing before a recording exists', () async {
    await cubit.upload();

    expect(cubit.state.status, RecordingStatus.idle);
    expect(repository.uploadedPath, isNull);
  });

  test('stop does not upload the recording', () async {
    await record();

    expect(cubit.state.status, RecordingStatus.recorded);
    expect(cubit.state.hasUploaded, isFalse);
    expect(repository.uploads, 0);
  });

  test('listening plays the recording kept on the device', () async {
    await record();

    final playing = cubit.play();
    await cubit.stopPlayback();
    await playing;

    expect(player.played, ['recitation.m4a']);
    expect(repository.uploads, 0);
  });

  test('listening is not available before a recording exists', () async {
    await cubit.play();

    expect(player.played, isEmpty);
    expect(cubit.state.status, RecordingStatus.idle);
  });

  test('re-recording replaces the local recording without uploading', () async {
    await record();
    recorder.path = 'second.m4a';

    await record();

    expect(recorder.starts, 2);
    expect(cubit.state.status, RecordingStatus.recorded);
    expect(repository.uploads, 0);

    final playing = cubit.play();
    await cubit.stopPlayback();
    await playing;
    expect(player.played, ['second.m4a']);
  });

  test('upload happens only when it is requested', () async {
    await record();
    final playing = cubit.play();
    await cubit.stopPlayback();
    await playing;
    expect(repository.uploads, 0);

    await cubit.upload();

    expect(repository.uploads, 1);
    expect(cubit.state.status, RecordingStatus.uploaded);
    expect(cubit.state.hasUploaded, isTrue);
  });

  test('upload reports its progress', () async {
    repository.progress = [0.25, 0.5, 1];
    await record();
    final progress = <double>[];
    final subscription = cubit.stream
        .where((state) => state.status == RecordingStatus.uploading)
        .listen((state) => progress.add(state.uploadProgress));

    await cubit.upload();
    // Lets the stream deliver the states emitted during the upload.
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(progress, [0, 0.25, 0.5, 1]);
    expect(cubit.state.status, RecordingStatus.uploaded);
  });

  test('an uploaded recording is replaced by a new upload', () async {
    await record();
    await cubit.upload();
    recorder.path = 'second.m4a';

    // Re-recording alone leaves the uploaded recording in place.
    await record();
    expect(cubit.state.status, RecordingStatus.recorded);
    expect(cubit.state.hasUploaded, isTrue);
    expect(repository.uploads, 1);
    expect(repository.uploadedPath, 'recitation.m4a');

    await cubit.upload();
    expect(cubit.state.status, RecordingStatus.uploaded);
    expect(repository.uploads, 2);
    expect(repository.uploadedPath, 'second.m4a');
  });

  test('a recording uploaded in an earlier visit can be replaced', () async {
    repository.uploaded = true;
    await cubit.load();

    await record();
    expect(repository.uploads, 0);

    await cubit.upload();
    expect(repository.uploads, 1);
    expect(cubit.state.status, RecordingStatus.uploaded);
  });

  test('a failed re-recording keeps the uploaded recording', () async {
    await record();
    await cubit.upload();
    recorder.path = null;

    await record();

    expect(cubit.state.status, RecordingStatus.uploaded);
    expect(cubit.state.hasUploaded, isTrue);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('a failed start keeps the current recording', () async {
    await record();
    recorder.startFailure = const AppFailure('تعذّر بدء التسجيل.');

    await cubit.start();

    expect(cubit.state.status, RecordingStatus.recorded);
    expect(cubit.state.errorMessage, 'تعذّر بدء التسجيل.');
  });
}
