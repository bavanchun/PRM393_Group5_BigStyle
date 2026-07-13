import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/refund_request/refund_request_bloc.dart';
import '../../blocs/refund_request/refund_request_event.dart';
import '../../blocs/refund_request/refund_request_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';

/// Reason-entry sheet for a customer requesting a refund on [orderId].
/// Dispatches [RefundRequestSubmit] on the [RefundRequestBloc] already
/// provided above [context], then closes once the submit completes.
Future<void> showRefundRequestSheet(
  BuildContext context, {
  required String orderId,
  required String userId,
}) {
  final bloc = context.read<RefundRequestBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: bloc,
        child: _RefundRequestSheetContent(orderId: orderId, userId: userId),
      );
    },
  );
}

class _RefundRequestSheetContent extends StatefulWidget {
  final String orderId;
  final String userId;

  const _RefundRequestSheetContent({
    required this.orderId,
    required this.userId,
  });

  @override
  State<_RefundRequestSheetContent> createState() =>
      _RefundRequestSheetContentState();
}

class _RefundRequestSheetContentState
    extends State<_RefundRequestSheetContent> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    context.read<RefundRequestBloc>().add(
      RefundRequestSubmit(
        orderId: widget.orderId,
        userId: widget.userId,
        reason: _reasonController.text.trim(),
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
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yêu cầu hoàn tiền', style: AppTypography.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cửa hàng sẽ xem xét và xử lý hoàn tiền thủ công sau khi duyệt yêu cầu.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Vui lòng nhập lý do yêu cầu hoàn tiền...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập lý do'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Gửi yêu cầu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
