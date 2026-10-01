import 'package:firebase_core/firebase_core.dart';

/// An error carrying an Arabic message ready to show the user.
class AppFailure implements Exception {
  const AppFailure(this.message);

  /// Maps a Firestore error to a user-facing failure.
  factory AppFailure.fromFirebase(FirebaseException e) {
    return switch (e.code) {
      'unavailable' || 'deadline-exceeded' => const AppFailure(
        'تعذّر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
      ),
      'permission-denied' => const AppFailure(
        'لا تملك صلاحية عرض هذه البيانات.',
      ),
      _ => const AppFailure('حدث خطأ غير متوقع. حاول مرة أخرى.'),
    };
  }

  final String message;

  @override
  String toString() => 'AppFailure: $message';
}
