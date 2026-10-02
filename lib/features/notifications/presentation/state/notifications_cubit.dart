import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.items);

  /// Newest first.
  final List<AppNotification> items;

  int get unreadCount => items.where((item) => !item.isRead).length;
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);

  final String message;
}

/// The notifications of the signed-in account, kept up to date while the app
/// is open.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, this._audience)
    : super(const NotificationsLoading());

  final NotificationsRepository _repository;

  /// Null when the account has nothing to be notified about, such as a
  /// supervisor without a square.
  final NotificationAudience? _audience;

  StreamSubscription<List<AppNotification>>? _subscription;

  /// Starts, or restarts, listening.
  void start() {
    final audience = _audience;
    _subscription?.cancel();
    if (audience == null) {
      emit(const NotificationsLoaded([]));
      return;
    }
    emit(const NotificationsLoading());
    _subscription = _repository
        .watch(audience)
        .listen(
          (items) => emit(NotificationsLoaded(items)),
          onError: (Object error) => emit(
            NotificationsError(
              error is AppFailure ? error.message : 'تعذّر تحميل الإشعارات.',
            ),
          ),
        );
  }

  /// Marks [notification] as read. The list updates through the stream.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _repository.markRead(notification.id);
    } on AppFailure {
      // It stays unread and can be opened again.
    }
  }

  Future<void> markAllRead() async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    await Future.wait([
      for (final item in current.items)
        if (!item.isRead) markRead(item),
    ]);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
