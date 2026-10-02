/// A notification from the `notifications` collection.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.isRead,
    this.createdAt,
  });

  /// A student's examination was submitted and needs the supervisor's review.
  static const String examSubmitted = 'exam_submitted';

  /// The result of the student's examination was approved.
  static const String examApproved = 'exam_approved';

  final String id;
  final String title;
  final String body;
  final String type;

  /// The ID of the examination the notification is about.
  final String relatedId;
  final bool isRead;
  final DateTime? createdAt;

  /// [toDate] converts a stored timestamp value.
  static AppNotification fromMap(
    String id,
    Map<String, dynamic> data, {
    required DateTime? Function(Object? value) toDate,
  }) {
    return AppNotification(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? '',
      relatedId: data['relatedId'] as String? ?? '',
      isRead: data['isRead'] == true,
      createdAt: toDate(data['createdAt']),
    );
  }
}

/// Whose notifications to show: those addressed to one account, or those
/// addressed to the supervisor of a square.
class NotificationAudience {
  const NotificationAudience.user(String this.userId) : squareId = null;

  const NotificationAudience.square(String this.squareId) : userId = null;

  final String? userId;
  final String? squareId;
}
