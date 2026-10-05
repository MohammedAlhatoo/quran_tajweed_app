import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/services/exam_notification_texts.dart';

/// In-app notifications only. The approval of a result is notified by the
/// supervisor's device, in the batch that approves it; the submission of an
/// examination, by the `submitExam` Cloud Function.
class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  /// The ID and the fields of the notification that tells [studentId] that
  /// the result of [examId] was approved.
  static (String id, Map<String, dynamic> data) examApproved({
    required String examId,
    required String studentId,
    required String courseName,
    required int finalScore,
    required bool passed,
  }) {
    return (
      '${examId}_result',
      {
        'userId': studentId,
        'squareId': null,
        'title': ExamNotificationTexts.approvedTitle,
        'body': ExamNotificationTexts.approvedBody(
          courseName: courseName,
          finalScore: finalScore,
          passed: passed,
        ),
        'type': AppNotification.examApproved,
        'relatedId': examId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  @override
  Stream<List<AppNotification>> watch(NotificationAudience audience) {
    // The security rules require the query to filter on the addressee.
    final notifications = _firestore.collection(
      FirebaseCollections.notifications,
    );
    final query = audience.userId != null
        ? notifications.where('userId', isEqualTo: audience.userId)
        : notifications.where('squareId', isEqualTo: audience.squareId);

    return query
        .snapshots()
        .map((snapshot) {
          final items = [
            for (final doc in snapshot.docs)
              AppNotification.fromMap(doc.id, doc.data(), toDate: _toDate),
          ];
          // Sorted here to avoid requiring a composite index. A notification
          // just written has no server time yet and counts as the newest.
          final newest = DateTime.now();
          items.sort(
            (a, b) => (b.createdAt ?? newest).compareTo(a.createdAt ?? newest),
          );
          return items;
        })
        .handleError(
          (Object error) => throw error is FirebaseException
              ? AppFailure.fromFirebase(error)
              : error,
        );
  }

  @override
  Future<void> markRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.notifications)
          .doc(notificationId)
          .update({'isRead': true});
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
