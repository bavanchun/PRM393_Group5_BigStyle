import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentOrdersHeader(),
            const SizedBox(height: 12),
            _buildRecentOrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Doanh thu hôm nay', '12.5tr', Icons.trending_up, AppColors.primary),
        _buildStatCard('Đơn hàng mới', '8', Icons.receipt_long, AppColors.success),
        _buildStatCard('Tổng sản phẩm', '156', Icons.inventory_2, AppColors.warning),
        _buildStatCard('Khách hàng', '234', Icons.people, AppColors.accent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displaySmall.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thao tác nhanh', style: AppTypography.headlineMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard(Icons.add_circle_outline, 'Thêm sản phẩm', AppColors.primary, () => _showComingSoon())),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.category_outlined, 'Danh mục', AppColors.warning, () => _showComingSoon())),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(Icons.local_offer_outlined, 'Khuyến mãi', AppColors.success, () => _showComingSoon())),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Đơn hàng gần đây', style: AppTypography.headlineMedium),
        TextButton(
          onPressed: () {},
          child: Text(
            'Xem tất cả',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersList() {
    return Column(
      children: [
        _buildOrderItem('DH-001', 'Nguyễn Thị Hương', '150,000đ', 'Đang giao'),
        _buildOrderItem('DH-002', 'Trần Văn Minh', '320,000đ', 'Chờ xác nhận'),
        _buildOrderItem('DH-003', 'Lê Thị Mai', '215,000đ', 'Đã giao'),
        _buildOrderItem('DH-004', 'Phạm Hoàng', '480,000đ', 'Đang chuẩn bị'),
      ],
    );
  }

  Widget _buildOrderItem(String id, String customer, String amount, String status) {
    Color statusColor;
    switch (status) {
      case 'Đang giao':
        statusColor = AppColors.warning;
      case 'Chờ xác nhận':
        statusColor = AppColors.error;
      case 'Đã giao':
        statusColor = AppColors.success;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(customer, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
