import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_error_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  void _loadNotifications() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<NotificationBloc>().add(NotificationLoad(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Thông báo')),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        // Surface transient failures (e.g. mark-read) that keep the list intact;
        // the empty-list case is handled by the full-screen error state below.
        listenWhen: (previous, current) =>
            current.error != null &&
            current.error != previous.error &&
            current.notifications.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.notifications.isEmpty) {
            return Center(
              child: AppErrorState(
                message: state.error!,
                onRetry: _loadNotifications,
              ),
            );
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? AppColors.background
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: notification.isRead
                        ? AppColors.textHint
                        : AppColors.primary,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: notification.isRead
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  notification.body,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTime(notification.createdAt),
                  style: AppTypography.caption,
                ),
                onTap: () {
                  if (!notification.isRead) {
                    context.read<NotificationBloc>().add(
                      NotificationMarkRead(notification.id),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
