import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/services/recitation_audio.dart';

/// Records with the device microphone into a temporary AAC (.m4a) file.
class DeviceRecitationRecorder implements RecitationRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          numChannels: 1,
        ),
        path: '${Directory.systemTemp.path}/recitation.m4a',
      );
    } on Exception {
      throw const AppFailure('تعذّر بدء التسجيل. حاول مرة أخرى.');
    }
  }

  @override
  Future<String?> stop() async {
    try {
      return await _recorder.stop();
    } on Exception {
      throw const AppFailure('تعذّر حفظ التسجيل. حاول مرة أخرى.');
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

class DeviceRecitationPlayer implements RecitationPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      await _player.play();
    } on Exception {
      throw const AppFailure('تعذّر تشغيل التسجيل.');
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
