import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/manager/manager_bloc.dart';
import '../../blocs/manager/manager_event.dart';
import '../../models/notification_model.dart';
import '../../models/order_status.dart';

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
    final isManager = context.watch<AuthBloc>().state.user?.isManager == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount > 0) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      '${state.unreadCount} chưa đọc',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('Chưa có thông báo nào', style: AppTypography.bodyMedium),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _buildNotificationTile(context, notification, isManager);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, NotificationModel notification, bool isManager) {
    final isUnread = !notification.isRead;

    // Icon based on type
    IconData icon;
    Color iconColor;
    if (notification.isNewOrder) {
      icon = Icons.shopping_bag_outlined;
      iconColor = AppColors.primary;
    } else if (notification.isOrderUpdate) {
      final status = notification.orderStatus;
      if (status == 'cancelled') {
        icon = Icons.cancel_outlined;
        iconColor = AppColors.error;
      } else if (status == 'delivered') {
        icon = Icons.check_circle_outline;
        iconColor = AppColors.success;
      } else {
        icon = Icons.receipt_long_outlined;
        iconColor = AppColors.primary;
      }
    } else {
      icon = Icons.notifications_outlined;
      iconColor = AppColors.primary;
    }

    return InkWell(
      onTap: () => _onTapNotification(context, notification, isManager),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread
                    ? iconColor.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isUnread ? iconColor : AppColors.textHint, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: isUnread ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isManager && notification.isNewOrder && isUnread) ...[
                    const SizedBox(height: 10),
                    _buildActionButtons(context, notification),
                  ],
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, NotificationModel notification) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCancelDialog(context, notification),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Từ chối'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _acceptOrder(context, notification),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Xác nhận'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _onTapNotification(
      BuildContext context, NotificationModel notification, bool isManager) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(NotificationMarkRead(notification.id));
    }

    // Navigate to order detail if it's an order notification
    if (notification.isOrderUpdate || notification.isNewOrder) {
      final orderId = notification.orderId;
      if (orderId != null) {
        Navigator.pushNamed(context, '/order-detail', arguments: orderId);
      }
    }
  }

  void _acceptOrder(BuildContext context, NotificationModel notification) {
    final orderId = notification.orderId;
    if (orderId == null) return;

    context.read<ManagerBloc>().add(ManagerUpdateOrderStatus(
      orderId: orderId,
      status: OrderStatus.confirmed,
    ));

    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(NotificationMarkRead(notification.id));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xác nhận đơn hàng'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showCancelDialog(BuildContext context, NotificationModel notification) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lý do từ chối (bắt buộc):',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              Navigator.pop(ctx);
              _cancelOrder(context, notification, reason);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(
      BuildContext context, NotificationModel notification, String reason) {
    final orderId = notification.orderId;
    if (orderId == null) return;

    context.read<ManagerBloc>().add(ManagerUpdateOrderStatus(
      orderId: orderId,
      status: OrderStatus.cancelled,
      reason: reason,
    ));

    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(NotificationMarkRead(notification.id));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã từ chối đơn hàng'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
