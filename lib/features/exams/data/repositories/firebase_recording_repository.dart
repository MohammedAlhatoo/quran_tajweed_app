import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/repositories/recording_repository.dart';

/// Keeps one recitation recording per examination in Firebase Storage.
class FirebaseRecordingRepository implements RecordingRepository {
  FirebaseRecordingRepository({required StorageService storageService})
    : _storage = storageService;

  final StorageService _storage;

  @override
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
  }) async {
    try {
      await _storage.uploadFile(
        path: recitationRecordingPath(examId),
        file: File(filePath),
        contentType: 'audio/mp4',
      );
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<bool> hasRecording(String examId) async {
    try {
      return await _storage.exists(recitationRecordingPath(examId));
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
