/// All methods throw `AppFailure` on error.
abstract interface class RecordingRepository {
  /// Uploads the recitation recording of [examId] from the local [filePath],
  /// replacing a previously uploaded one.
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
  });

  /// Whether a recitation recording of [examId] has been uploaded.
  Future<bool> hasRecording(String examId);
}
