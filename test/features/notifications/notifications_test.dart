import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/notifications/domain/entities/app_notification.dart';
import 'package:quran_tajweed_app/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:quran_tajweed_app/features/notifications/domain/services/exam_notification_texts.dart';
import 'package:quran_tajweed_app/features/notifications/presentation/state/notifications_cubit.dart';

AppNotification _notification(String id, {bool isRead = false}) {
  return AppNotification(
    id: id,
    title: 'عنوان',
    body: 'نص',
    type: AppNotification.examApproved,
    relatedId: 'exam-1',
    isRead: isRead,
  );
}

class _FakeNotificationsRepository implements NotificationsRepository {
  final controller = StreamController<List<AppNotification>>.broadcast();
  NotificationAudience? audience;
  final read = <String>[];
  AppFailure? failure;

  @override
  Stream<List<AppNotification>> watch(NotificationAudience audience) {
    this.audience = audience;
    return controller.stream;
  }

  @override
  Future<void> markRead(String notificationId) async {
    if (failure case final failure?) throw failure;
    read.add(notificationId);
  }
}

DateTime? _noDate(Object? value) => null;

void main() {
  group('ExamNotificationTexts', () {
    test('the result notification states passed or failed', () {
      expect(
        ExamNotificationTexts.approvedBody(
          courseName: 'تمهيدية',
          finalScore: 84,
          passed: true,
        ),
        allOf(contains('ناجح'), contains('84'), contains('تمهيدية')),
      );
      expect(
        ExamNotificationTexts.approvedBody(
          courseName: 'تمهيدية',
          finalScore: 55,
          passed: false,
        ),
        allOf(contains('راسب'), isNot(contains('ناجح'))),
      );
    });
  });

  test('AppNotification.fromMap reads an unread notification', () {
    final notification = AppNotification.fromMap('exam-1_result', {
      'title': 'تم اعتماد نتيجة اختبارك',
      'body': 'ناجح',
      'type': 'exam_approved',
      'relatedId': 'exam-1',
      'isRead': false,
    }, toDate: _noDate);

    expect(notification.relatedId, 'exam-1');
    expect(notification.isRead, isFalse);
    expect(notification.type, AppNotification.examApproved);
  });

  group('NotificationsCubit', () {
    late _FakeNotificationsRepository repository;

    setUp(() => repository = _FakeNotificationsRepository());

    test('follows the notifications of its audience', () async {
      final cubit = NotificationsCubit(
        repository,
        const NotificationAudience.square('square-1'),
      )..start();
      expect(cubit.state, isA<NotificationsLoading>());

      repository.controller.add([
        _notification('a'),
        _notification('b', isRead: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(repository.audience!.squareId, 'square-1');
      expect(repository.audience!.userId, isNull);
      final state = cubit.state as NotificationsLoaded;
      expect(state.items, hasLength(2));
      expect(state.unreadCount, 1);
      await cubit.close();
    });

    test('an account without an audience has no notifications', () {
      final cubit = NotificationsCubit(repository, null)..start();

      expect((cubit.state as NotificationsLoaded).items, isEmpty);
      expect(repository.audience, isNull);
    });

    test('marks only unread notifications as read', () async {
      final cubit = NotificationsCubit(
        repository,
        const NotificationAudience.user('uid-1'),
      )..start();
      repository.controller.add([
        _notification('a'),
        _notification('b', isRead: true),
        _notification('c'),
      ]);
      await Future<void>.delayed(Duration.zero);

      await cubit.markRead(_notification('b', isRead: true));
      expect(repository.read, isEmpty);

      await cubit.markAllRead();
      expect(repository.read, ['a', 'c']);
      await cubit.close();
    });

    test('reports a failed stream and survives a failed mark', () async {
      final cubit = NotificationsCubit(
        repository,
        const NotificationAudience.user('uid-1'),
      )..start();
      repository.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.markRead(_notification('a'));
      expect(repository.read, isEmpty);

      repository.controller.addError(const AppFailure('تعذّر الاتصال.'));
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as NotificationsError).message, 'تعذّر الاتصال.');
      await cubit.close();
    });
  });
}
