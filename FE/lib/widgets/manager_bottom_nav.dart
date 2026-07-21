import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/support_inbox/support_inbox_bloc.dart';
import '../blocs/support_inbox/support_inbox_state.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_typography.dart';

class ManagerBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const ManagerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textHint,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: AppTypography.labelSmall
                  .copyWith(color: AppColors.primary, fontSize: 11),
              unselectedLabelStyle:
                  AppTypography.labelSmall.copyWith(fontSize: 11),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Tổng quan',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Sản phẩm',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Đơn hàng',
                ),
                BottomNavigationBarItem(
                  icon: const _MessagesNavIcon(Icons.chat_bubble_outline),
                  activeIcon: const _MessagesNavIcon(Icons.chat_bubble),
                  label: 'Tin nhắn',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Cá nhân',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chat icon carrying a live unread badge from the app-scoped inbox bloc.
class _MessagesNavIcon extends StatelessWidget {
  final IconData icon;
  const _MessagesNavIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupportInboxBloc, SupportInboxState>(
      buildWhen: (p, c) => p.totalUnread != c.totalUnread,
      builder: (context, state) {
        return Badge.count(
          count: state.totalUnread,
          isLabelVisible: state.totalUnread > 0,
          child: Icon(icon),
        );
      },
    );
  }
}
