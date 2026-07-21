import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/refund_request/refund_request_bloc.dart';
import '../../blocs/refund_request/refund_request_event.dart';
import '../../blocs/refund_request/refund_request_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/refund_request_model.dart';

/// Approve/reject sheet for [request], mirroring
/// order_status_update_sheet.dart's pattern. Rejecting requires a note
/// (shown to the customer); approving needs no extra input — the RPC
/// atomically flips the order to refunded and the existing order-status
/// trigger notifies the customer.
Future<void> showRefundDecisionSheet(
  BuildContext context,
  RefundRequestModel request,
) {
  final bloc = context.read<RefundRequestBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.bottomSheetRadius),
      ),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: bloc,
        child: _RefundDecisionSheetContent(request: request),
      );
    },
  );
}

class _RefundDecisionSheetContent extends StatefulWidget {
  final RefundRequestModel request;

  const _RefundDecisionSheetContent({required this.request});

  @override
  State<_RefundDecisionSheetContent> createState() =>
      _RefundDecisionSheetContentState();
}

class _RefundDecisionSheetContentState
    extends State<_RefundDecisionSheetContent> {
  bool _submitting = false;

  Future<void> _approve() async {
    _decide(RefundRequestStatus.approved);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối yêu cầu hoàn tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do từ chối (khách sẽ nhìn thấy):'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              Navigator.pop(dialogContext, text);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    if (note == null || !mounted) return;
    _decide(RefundRequestStatus.rejected, note);
  }

  void _decide(RefundRequestStatus decision, [String? note]) {
    setState(() => _submitting = true);
    context.read<RefundRequestBloc>().add(
      RefundRequestDecide(
        requestId: widget.request.id,
        orderId: widget.request.orderId,
        decision: decision,
        note: note,
      ),
    );
  }

  void _onStateChange(BuildContext context, RefundRequestState state) {
    if (!_submitting) return;
    if (state.isProcessing) return;
    if (state.error != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
      return;
    }
    setState(() => _submitting = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RefundRequestBloc, RefundRequestState>(
      listenWhen: (previous, current) =>
          previous.isProcessing != current.isProcessing ||
          previous.error != current.error,
      listener: _onStateChange,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yêu cầu hoàn tiền', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Lý do của khách:', style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text(widget.request.reason, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _approve,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Chấp nhận'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
