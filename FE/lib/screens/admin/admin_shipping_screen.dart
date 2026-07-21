import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../models/shipping_rate_model.dart';
import '../../services/shipping_service.dart';

class AdminShippingScreen extends StatefulWidget {
  const AdminShippingScreen({super.key});

  @override
  State<AdminShippingScreen> createState() => _AdminShippingScreenState();
}

class _AdminShippingScreenState extends State<AdminShippingScreen> {
  final _shippingService = ShippingService();
  List<ShippingRateModel> _rates = [];
  bool _isLoading = true;

  // Common Vietnam provinces
  final _provinces = [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Long An',
    'Bà Rịa - Vũng Tàu',
    'Kiên Giang',
    'Đắk Lắk',
    'Lâm Đồng',
    'Thanh Hóa',
    'Nghệ An',
    'Hà Tĩnh',
    'Quảng Ninh',
    'Thanh Hóa',
    'Nghệ An',
    'Hà Tĩnh',
  ];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    try {
      final rates = await _shippingService.getAllRates();
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  Future<void> _showUpsertDialog({ShippingRateModel? existing}) async {
    String fromProvince = existing?.fromProvince ?? _provinces[0];
    String toProvince = existing?.toProvince ?? _provinces[1];
    final feeController = TextEditingController(
        text: existing?.baseFee.toStringAsFixed(0) ?? '30000');
    final freeThresholdController = TextEditingController(
        text: existing?.freeThreshold.toStringAsFixed(0) ?? '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Thêm tuyến vận chuyển' : 'Sửa tuyến vận chuyển'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: fromProvince,
                  decoration: const InputDecoration(labelText: 'Từ tỉnh/thành *'),
                  items: _provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => fromProvince = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: toProvince,
                  decoration: const InputDecoration(labelText: 'Đến tỉnh/thành *'),
                  items: _provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => toProvince = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  decoration: const InputDecoration(
                    labelText: 'Phí cơ bản (VND) *',
                    suffixText: 'VND',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: freeThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Miễn ship từ (VND)',
                    suffixText: 'VND',
                    helperText: 'Đơn hàng >= số tiền này được miễn ship',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final fee = double.tryParse(feeController.text) ?? 30000;
      final threshold = double.tryParse(freeThresholdController.text) ?? 0;

      final rate = ShippingRateModel(
        id: existing?.id ?? '',
        fromProvince: fromProvince,
        toProvince: toProvince,
        baseFee: fee,
        freeThreshold: threshold,
        isActive: existing?.isActive ?? true,
      );

      try {
        await _shippingService.upsertRate(rate);
        _loadRates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu tuyến vận chuyển')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi lưu: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(ShippingRateModel rate) async {
    try {
      await _shippingService.toggleRate(rate.id, !rate.isActive);
      _loadRates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _deleteRate(ShippingRateModel rate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tuyến vận chuyển?'),
        content: Text('Xóa ${rate.fromProvince} → ${rate.toProvince}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _shippingService.deleteRate(rate.id);
        _loadRates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phí vận chuyển'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUpsertDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('Chưa có tuyến vận chuyển nào',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _showUpsertDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm tuyến'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _rates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final rate = _rates[index];
                    return _buildRateCard(rate);
                  },
                ),
    );
  }

  Widget _buildRateCard(ShippingRateModel rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: rate.isActive ? AppColors.border : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${rate.fromProvince} → ${rate.toProvince}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: rate.isActive
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    if (!rate.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Tạm tắt',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.error)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Phí: ${rate.baseFee.toStringAsFixed(0)}đ',
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary),
                ),
                if (rate.freeThreshold > 0)
                  Text(
                    'Miễn ship từ ${rate.freeThreshold.toStringAsFixed(0)}đ',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.success),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _showUpsertDialog(existing: rate);
              if (value == 'toggle') _toggleActive(rate);
              if (value == 'delete') _deleteRate(rate);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(rate.isActive ? 'Tắt' : 'Bật'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Xóa', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
