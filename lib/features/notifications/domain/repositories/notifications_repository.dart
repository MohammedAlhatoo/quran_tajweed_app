import '../entities/app_notification.dart';

/// Reads the notifications written by examination events. Errors are
/// `AppFailure`s.
abstract interface class NotificationsRepository {
  /// The notifications of [audience], newest first, kept up to date.
  Stream<List<AppNotification>> watch(NotificationAudience audience);

  Future<void> markRead(String notificationId);
}
