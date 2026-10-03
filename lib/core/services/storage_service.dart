import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Firebase Storage.
class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads [file] to [path], replacing any object already there.
  /// [onProgress] receives the uploaded share, from 0 to 1.
  Future<void> uploadFile({
    required String path,
    required File file,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final task = _storage
        .ref(path)
        .putFile(file, SettableMetadata(contentType: contentType));
    final progress = onProgress == null
        ? null
        : task.snapshotEvents.listen(
            (snapshot) {
              if (snapshot.totalBytes > 0) {
                onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
              }
            },
            // The failure is reported by the task itself.
            onError: (_) {},
          );
    try {
      await task;
    } finally {
      await progress?.cancel();
    }
  }

  /// Downloads the object at [path] into [file], replacing its contents.
  Future<void> downloadFile({required String path, required File file}) async {
    await _storage.ref(path).writeToFile(file);
  }

  Future<bool> exists(String path) async {
    try {
      await _storage.ref(path).getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }
}
