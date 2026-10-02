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

  @override
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
  }) async {
    if (failure case final failure?) throw failure;
    uploadedPath = filePath;
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

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async => starts++;

  @override
  Future<String?> stop() async => path;

  @override
  Future<void> dispose() async {}
}

class _FakePlayer implements RecitationPlayer {
  Completer<void>? _playback;

  @override
  Future<void> play(String filePath) => (_playback = Completer<void>()).future;

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
}
