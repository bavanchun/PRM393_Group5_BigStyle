import 'package:flutter/material.dart';
import '../../../utils/currency_format.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/manager_voucher/manager_voucher_bloc.dart';
import '../../../blocs/manager_voucher/manager_voucher_event.dart';
import '../../../blocs/manager_voucher/manager_voucher_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/voucher_model.dart';
import 'manager_voucher_edit_sheet.dart';

class ManagerVoucherListScreen extends StatefulWidget {
  const ManagerVoucherListScreen({super.key});

  @override
  State<ManagerVoucherListScreen> createState() =>
      _ManagerVoucherListScreenState();
}

class _ManagerVoucherListScreenState extends State<ManagerVoucherListScreen> {
  // Last successfully loaded list. Kept so transient states (OperationSuccess
  // / Error) emitted while the edit sheet is open do not wipe the list out
  // from under the modal.
  List<VoucherModel>? _vouchers;

  @override
  void initState() {
    super.initState();
    context.read<ManagerVoucherBloc>().add(LoadManagerVouchersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý mã giảm giá'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showManagerVoucherEditSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Thêm mã giảm giá'),
      ),
      body: BlocConsumer<ManagerVoucherBloc, ManagerVoucherState>(
        listener: (context, state) {
          if (state is ManagerVoucherLoaded) {
            setState(() => _vouchers = state.vouchers);
          } else if (state is ManagerVoucherOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ManagerVoucherError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final vouchers = _vouchers;
          if (vouchers != null) {
            if (vouchers.isEmpty) {
              return _CenteredMessage(
                message: 'Chưa có mã giảm giá',
                onRefresh: _reload,
              );
            }
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: vouchers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) =>
                    _VoucherTile(voucher: vouchers[index]),
              ),
            );
          }
          // No data loaded yet.
          if (state is ManagerVoucherError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Không tải được mã giảm giá',
                      style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => context
                        .read<ManagerVoucherBloc>()
                        .add(LoadManagerVouchersEvent()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<void> _reload() async {
    context.read<ManagerVoucherBloc>().add(LoadManagerVouchersEvent());
    await context.read<ManagerVoucherBloc>().stream.firstWhere(
          (s) => s is! ManagerVoucherLoading,
        );
  }
}

/// Empty-state message that still supports pull-to-refresh.
class _CenteredMessage extends StatelessWidget {
  final String message;
  final Future<void> Function() onRefresh;

  const _CenteredMessage({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(message, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Human-readable discount summary, e.g. "Giảm 10%" or "Giảm 20.000đ".
String _discountSummary(VoucherModel voucher) {
  if (voucher.isPercentage) {
    final percent = voucher.value % 1 == 0
        ? voucher.value.toStringAsFixed(0)
        : voucher.value.toString();
    return 'Giảm $percent%';
  }
  return 'Giảm ${formatVnd(voucher.value)}';
}

class _VoucherTile extends StatelessWidget {
  final VoucherModel voucher;

  const _VoucherTile({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showManagerVoucherEditSheet(context, existing: voucher),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.local_offer_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(voucher.code, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${_discountSummary(voucher)} · Đơn tối thiểu ${formatVnd(voucher.minOrderAmount)}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusBadge(isActive: voucher.isActive),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Đang bật' : 'Đã tắt',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
