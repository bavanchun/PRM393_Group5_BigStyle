import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/manager_voucher/manager_voucher_bloc.dart';
import '../../../blocs/manager_voucher/manager_voucher_event.dart';
import '../../../blocs/manager_voucher/manager_voucher_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/voucher_model.dart';

/// Opens the create/edit bottom sheet for a voucher. Pass [existing] to edit;
/// omit it to create. Dispatches on the [ManagerVoucherBloc] provided above
/// [context].
Future<void> showManagerVoucherEditSheet(
  BuildContext context, {
  VoucherModel? existing,
}) {
  final bloc = context.read<ManagerVoucherBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _VoucherEditSheetContent(existing: existing),
    ),
  );
}

class _VoucherEditSheetContent extends StatefulWidget {
  final VoucherModel? existing;

  const _VoucherEditSheetContent({this.existing});

  @override
  State<_VoucherEditSheetContent> createState() =>
      _VoucherEditSheetContentState();
}

class _VoucherEditSheetContentState extends State<_VoucherEditSheetContent> {
  late final TextEditingController _codeController;
  late final TextEditingController _valueController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _maxDiscountController;
  String _type = 'percentage';
  bool _isActive = true;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _codeController = TextEditingController(text: v?.code ?? '');
    _valueController = TextEditingController(
      text: v != null ? _trimZeros(v.value) : '',
    );
    _minOrderController = TextEditingController(
      text: v != null ? _trimZeros(v.minOrderAmount) : '0',
    );
    _maxDiscountController = TextEditingController(
      text: v?.maxDiscount != null ? _trimZeros(v!.maxDiscount!) : '',
    );
    _type = v?.type ?? 'percentage';
    _isActive = v?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  static String _trimZeros(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();

  void _submit() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Mã giảm giá không được để trống');
      return;
    }
    final value = double.tryParse(_valueController.text.trim());
    if (value == null || value < 0) {
      setState(() => _error = 'Giá trị giảm không hợp lệ');
      return;
    }
    if (_type == 'percentage' && value > 100) {
      setState(() => _error = 'Phần trăm giảm không được vượt quá 100%');
      return;
    }
    final minOrder = double.tryParse(_minOrderController.text.trim()) ?? 0;
    final maxDiscountText = _maxDiscountController.text.trim();
    final maxDiscount = maxDiscountText.isEmpty
        ? null
        : double.tryParse(maxDiscountText);

    setState(() {
      _submitting = true;
      _error = null;
    });

    final bloc = context.read<ManagerVoucherBloc>();
    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        code: code,
        type: _type,
        value: value,
        minOrderAmount: minOrder,
        maxDiscount: maxDiscount,
        isActive: _isActive,
      );
      bloc.add(UpdateManagerVoucherEvent(updated));
    } else {
      bloc.add(
        CreateManagerVoucherEvent(
          VoucherModel(
            code: code,
            type: _type,
            value: value,
            minOrderAmount: minOrder,
            maxDiscount: maxDiscount,
            isActive: _isActive,
          ),
        ),
      );
    }
  }

  void _onState(BuildContext context, ManagerVoucherState state) {
    if (state is ManagerVoucherOperationSuccess && _submitting) {
      Navigator.of(context).pop();
      return;
    }
    if (state is ManagerVoucherError) {
      setState(() {
        _submitting = false;
        _error = state.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return BlocListener<ManagerVoucherBloc, ManagerVoucherState>(
      listener: _onState,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md + bottomInset,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Sửa mã giảm giá' : 'Thêm mã giảm giá',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Mã giảm giá *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Phần trăm (%)'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Số tiền cố định (đ)'),
                    ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _type = v ?? 'percentage'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _type == 'percentage'
                        ? 'Giá trị giảm (%) *'
                        : 'Giá trị giảm (đ) *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _minOrderController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Đơn hàng tối thiểu (đ)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_type == 'percentage') ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _maxDiscountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Giảm tối đa (đ, tuỳ chọn)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang bật'),
                  value: _isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() => _isActive = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _error!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Lưu thay đổi' : 'Tạo mã giảm giá'),
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

/// Forces the voucher code field to uppercase as the user types.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
