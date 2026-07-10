import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';
import '../config/theme/app_typography.dart';
import '../config/theme/status_colors.dart';
import '../models/order_status.dart';

/// Tonal status badge — light-tint background + dark token text.
/// Consolidates the near-identical status-color switches duplicated across
/// orders_screen.dart (`_statusColor`) and manager_order_card.dart
/// (`managerOrderStatusColor`), and enforces the tonal rule from
/// docs/design-tokens-v2.md (never solid-fill + white text for
/// success/warning).
class StatusBadge extends StatelessWidget {
  final String label;
  final OrderStatus status;

  const StatusBadge({super.key, required this.label, required this.status});

  Color _tone(BuildContext context) {
    final statusColors = Theme.of(context).extension<StatusColors>()!;
    return switch (status) {
      OrderStatus.pending => statusColors.warning,
      OrderStatus.confirmed => AppColors.primary,
      OrderStatus.shipping => statusColors.info,
      OrderStatus.delivered => statusColors.success,
      OrderStatus.cancelled => statusColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: tone,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
