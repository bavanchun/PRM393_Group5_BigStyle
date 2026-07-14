import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/customer_address_model.dart';
import '../../services/address_service.dart';
import 'address_form_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _addressService = AddressService();
  List<CustomerAddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    final addresses = await _addressService.getAddresses(userId);
    if (!mounted) return;
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _setDefault(CustomerAddressModel addr) async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    await _addressService.setDefault(addr.id, userId);
    _loadAddresses();
  }

  Future<void> _deleteAddress(CustomerAddressModel addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text('Bạn muốn xóa địa chỉ "${addr.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _addressService.deleteAddress(addr.id);
      _loadAddresses();
    }
  }

  Future<void> _addOrEdit({CustomerAddressModel? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(existing: existing),
      ),
    );
    if (result == true) _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        actions: [
          TextButton.icon(
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Thêm'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('Chưa có địa chỉ nào',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _addOrEdit(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm địa chỉ'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    return _buildAddressCard(addr);
                  },
                ),
    );
  }

  Widget _buildAddressCard(CustomerAddressModel addr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: addr.isDefault
              ? AppColors.primary
              : AppColors.border,
          width: addr.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(addr.label,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              if (addr.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Mặc định',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _addOrEdit(existing: addr);
                  if (value == 'default') _setDefault(addr);
                  if (value == 'delete') _deleteAddress(addr);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  if (!addr.isDefault)
                    const PopupMenuItem(
                        value: 'default', child: Text('Đặt mặc định')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${addr.fullName}${addr.phone != null ? ' - ${addr.phone}' : ''}',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(addr.address,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          if (addr.district != null || addr.province.isNotEmpty)
            Text(
              [
                if (addr.ward != null) addr.ward,
                addr.district,
                addr.province,
              ].whereType<String>().join(', '),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}
