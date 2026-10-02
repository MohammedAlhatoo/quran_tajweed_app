import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Firebase Storage.
class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads [file] to [path], replacing any object already there.
  Future<void> uploadFile({
    required String path,
    required File file,
    required String contentType,
  }) async {
    await _storage
        .ref(path)
        .putFile(file, SettableMetadata(contentType: contentType));
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
