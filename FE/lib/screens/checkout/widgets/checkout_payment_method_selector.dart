import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';

class CheckoutPaymentMethodSelector extends StatelessWidget {
  const CheckoutPaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PaymentMethodOption(
            value: 'cod',
            selectedValue: value,
            icon: Icons.payments_outlined,
            label: 'Thanh toán khi nhận hàng',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PaymentMethodOption(
            value: 'bank_transfer',
            selectedValue: value,
            icon: Icons.qr_code_2_outlined,
            label: 'Chuyển khoản (SePay)',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.value,
    required this.selectedValue,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final String selectedValue;
  final IconData icon;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedValue == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
