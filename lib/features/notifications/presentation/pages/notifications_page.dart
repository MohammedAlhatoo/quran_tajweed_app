import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../state/notifications_cubit.dart';

/// The notifications of the signed-in account as a full screen.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.onOpen});

  /// Opens what a notification is about.
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('الإشعارات'),
      ),
      body: NotificationsView(onOpen: onOpen),
    );
  }
}

/// The list of notifications, newest first. Opening one marks it as read.
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key, required this.onOpen});

  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();

        return switch (state) {
          NotificationsLoading() => const AppLoadingView(),
          NotificationsError(:final message) => AppMessageView(
            message: message,
            onRetry: cubit.start,
          ),
          NotificationsLoaded(:final items) when items.isEmpty =>
            const AppMessageView(message: 'لا توجد إشعارات.'),
          NotificationsLoaded(:final items, :final unreadCount) =>
            ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // The "mark all as read" action comes first.
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: unreadCount == 0 ? null : cubit.markAllRead,
                      child: Text('تعليم الكل كمقروء ($unreadCount)'),
                    ),
                  );
                }
                final item = items[index - 1];
                return _NotificationCard(
                  notification: item,
                  onTap: () {
                    cubit.markRead(item);
                    onOpen(item);
                  },
                );
              },
            ),
        };
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final unread = !notification.isRead;
    final createdAt = notification.createdAt;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unread ? AppColors.optionSelectedBackground : AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: unread ? AppColors.optionSelectedBorder : AppColors.divider,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: unread
                          ? AppColors.optionSelectedMark
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppTextStyles.cairo(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          lineHeight: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: AppTextStyles.cairo(
                          size: 13,
                          weight: FontWeight.w500,
                          color: AppColors.bodyText,
                          lineHeight: 20,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(createdAt),
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.cairo(
                            size: 11,
                            weight: FontWeight.w500,
                            color: AppColors.textHint,
                            lineHeight: 16.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
