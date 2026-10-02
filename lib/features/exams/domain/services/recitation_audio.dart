/// Records the recitation to a local file. Methods throw `AppFailure` on
/// error.
abstract interface class RecitationRecorder {
  /// Asks for the microphone permission when it has not been decided yet.
  Future<bool> hasPermission();

  Future<void> start();

  /// Returns the path of the recorded file, or null when nothing was recorded.
  Future<String?> stop();

  Future<void> dispose();
}

/// Plays a recorded recitation back. Methods throw `AppFailure` on error.
abstract interface class RecitationPlayer {
  /// Completes when the playback reaches the end or is stopped.
  Future<void> play(String filePath);

  Future<void> stop();

  Future<void> dispose();
}
