import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/manager_dashboard_stats.dart';
import '../../utils/currency_format.dart';

class ManagerStatsGrid extends StatelessWidget {
  final ManagerDashboardStats stats;

  const ManagerStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Doanh thu hôm nay',
          value: formatVnd(stats.todayRevenue),
          icon: Icons.trending_up,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Đơn chờ xác nhận',
          value: '${stats.pendingOrderCount}',
          icon: Icons.receipt_long,
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Tổng sản phẩm',
          value: '${stats.productCount}',
          icon: Icons.inventory_2,
          color: AppColors.warning,
        ),
        _StatCard(
          label: 'Khách hàng',
          value: '${stats.customerCount}',
          icon: Icons.people,
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
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
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displaySmall.copyWith(
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ManagerQuickActions extends StatelessWidget {
  final VoidCallback onManageCategories;
  final VoidCallback onAddProduct;
  final VoidCallback onManageVouchers;

  const ManagerQuickActions({
    super.key,
    required this.onManageCategories,
    required this.onAddProduct,
    required this.onManageVouchers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thao tác nhanh', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _ActionCard(
              icon: Icons.add_circle_outline,
              label: 'Thêm sản phẩm',
              color: AppColors.primary,
              onTap: onAddProduct,
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionCard(
              icon: Icons.category_outlined,
              label: 'Danh mục',
              color: AppColors.warning,
              onTap: onManageCategories,
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionCard(
              icon: Icons.local_offer_outlined,
              label: 'Khuyến mãi',
              color: AppColors.success,
              onTap: onManageVouchers,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 2,
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
      ),
    );
  }
}
