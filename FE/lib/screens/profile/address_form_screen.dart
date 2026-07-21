import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/customer_address_model.dart';
import '../../services/address_service.dart';
import '../../services/vietnam_address_service.dart';

class AddressFormScreen extends StatefulWidget {
  final CustomerAddressModel? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressService = AddressService();
  final _vietnamAddressService = VietnamAddressService();
  bool _saving = false;

  String _label = 'Nhà';
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late bool _isDefault;

  // Dropdown data
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;
  bool _loadingProvinces = true;
  bool _loadingDistricts = false;
  bool _loadingWards = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.existing;
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _addressController = TextEditingController(text: addr?.address ?? '');
    _label = addr?.label ?? 'Nhà';
    _isDefault = addr?.isDefault ?? false;
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final provinces = await _vietnamAddressService.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _loadingProvinces = false;
      });
      // If editing, try to match existing province
      if (_isEditing && widget.existing!.province.isNotEmpty) {
        final match = provinces.cast<Province?>().firstWhere(
            (p) => p!.name == widget.existing!.province,
            orElse: () => null);
        if (match != null) {
          _selectedProvince = match;
          _loadDistricts(match.code);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadDistricts(int provinceCode) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _wards = [];
      _selectedWard = null;
    });
    try {
      final districts = await _vietnamAddressService.getDistricts(provinceCode);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });
      // If editing, try to match existing district
      if (_isEditing && widget.existing!.district != null && widget.existing!.district!.isNotEmpty) {
        final match = districts.cast<District?>().firstWhere(
            (d) => d!.name == widget.existing!.district,
            orElse: () => null);
        if (match != null) {
          _selectedDistrict = match;
          _loadWards(match.code);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadWards(int districtCode) async {
    setState(() {
      _loadingWards = true;
      _wards = [];
      _selectedWard = null;
    });
    try {
      final wards = await _vietnamAddressService.getWards(districtCode);
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _loadingWards = false;
      });
      // If editing, try to match existing ward
      if (_isEditing && widget.existing!.ward != null && widget.existing!.ward!.isNotEmpty) {
        final match = wards.cast<Ward?>().firstWhere(
            (w) => w!.name == widget.existing!.ward,
            orElse: () => null);
        if (match != null) {
          _selectedWard = match;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingWards = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    final addr = CustomerAddressModel(
      id: widget.existing?.id ?? '',
      userId: userId,
      label: _label,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim(),
      province: _selectedProvince?.name ?? '',
      district: _selectedDistrict?.name,
      ward: _selectedWard?.name,
      isDefault: _isDefault,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEditing) {
        await _addressService.updateAddress(addr);
      } else {
        await _addressService.createAddress(addr);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu địa chỉ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Label chips
            Text('Nhãn',
                style:
                    AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Nhà', 'Cơ quan', 'Khác'].map((l) {
                final active = l == _label;
                return ChoiceChip(
                  label: Text(l),
                  selected: active,
                  onSelected: (_) => setState(() => _label = l),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Họ và tên người nhận *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration:
                  const InputDecoration(labelText: 'Địa chỉ cụ thể (số nhà, đường) *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 16),
            // Province dropdown
            DropdownButtonFormField<Province>(
              initialValue: _selectedProvince,
              decoration: const InputDecoration(
                labelText: 'Tỉnh/Thành phố *',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              isExpanded: true,
              items: _provinces
                  .map((p) => DropdownMenuItem(
                      value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _loadingProvinces
                  ? null
                  : (p) {
                      if (p == null) return;
                      setState(() {
                        _selectedProvince = p;
                        _selectedDistrict = null;
                        _selectedWard = null;
                        _districts = [];
                        _wards = [];
                      });
                      _loadDistricts(p.code);
                    },
              validator: (v) => v == null ? 'Chọn tỉnh/thành phố' : null,
            ),
            const SizedBox(height: 12),
            // District dropdown
            DropdownButtonFormField<District>(
              initialValue: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'Quận/Huyện',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              isExpanded: true,
              items: _districts
                  .map((d) => DropdownMenuItem(
                      value: d, child: Text(d.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (_loadingDistricts || _districts.isEmpty)
                  ? null
                  : (d) {
                      if (d == null) return;
                      setState(() {
                        _selectedDistrict = d;
                        _selectedWard = null;
                        _wards = [];
                      });
                      _loadWards(d.code);
                    },
            ),
            const SizedBox(height: 12),
            // Ward dropdown
            DropdownButtonFormField<Ward>(
              initialValue: _selectedWard,
              decoration: const InputDecoration(
                labelText: 'Phường/Xã',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              isExpanded: true,
              items: _wards
                  .map((w) => DropdownMenuItem(
                      value: w, child: Text(w.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (_loadingWards || _wards.isEmpty)
                  ? null
                  : (w) => setState(() => _selectedWard = w),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Đặt làm mặc định'),
              subtitle: const Text('Dùng cho đơn hàng tiếp theo',
                  style: TextStyle(fontSize: 12)),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Cập nhật' : 'Thêm địa chỉ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
