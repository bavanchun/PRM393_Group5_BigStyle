import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';

class CheckoutPriceSummary extends StatelessWidget {
  const CheckoutPriceSummary({
    super.key,
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.total,
  });

  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          _PriceRow('Tạm tính', subtotal),
          const SizedBox(height: 8),
          _PriceRow('Phí vận chuyển', shippingFee),
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow('Giảm giá', -discountAmount),
          ],
          const Divider(height: 24),
          _PriceRow('Tổng cộng', total, isTotal: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount, {this.isTotal = false});

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.headlineSmall
              : AppTypography.bodyMedium,
        ),
        Text(
          '${amount.toStringAsFixed(0)}đ',
          style: isTotal
              ? AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
