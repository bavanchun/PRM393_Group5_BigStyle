import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/checkout/checkout_bloc.dart';
import '../../blocs/checkout/checkout_event.dart';
import '../../blocs/checkout/checkout_state.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/customer_address_model.dart';
import '../../services/address_service.dart';
import '../../services/shipping_service.dart';
import '../../services/voucher_service.dart';
import '../../utils/currency_format.dart';
import '../../utils/haptics.dart';
import '../../widgets/animated_success_check.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'payment_qr_screen.dart';
import 'widgets/checkout_item_list.dart';
import 'widgets/checkout_payment_method_selector.dart';
import 'widgets/checkout_price_summary.dart';
import 'widgets/checkout_voucher_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _promoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _voucherService = VoucherService();
  final _addressService = AddressService();
  final _shippingService = ShippingService();

  List<String>? _selectedIds;
  String _paymentMethod = 'cod';

  // Address
  List<CustomerAddressModel> _savedAddresses = [];
  CustomerAddressModel? _selectedAddress;
  bool _isLoadingAddresses = true;

  // Location
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Dynamic shipping fee
  double _shippingFee = AppConfig.flatShippingFee;

  // Promo
  String? _promoCode;
  double _discountAmount = 0;
  bool _applyingPromo = false;
  String? _promoError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedIds == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _selectedIds = (args['selectedIds'] as List?)?.cast<String>();
      } else {
        _selectedIds = const [];
      }
      _loadAddresses();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    try {
      final addresses = await _addressService.getAddresses(userId);
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
        _isLoadingAddresses = false;
      });
      // Auto-select default address
      final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
      if (defaultAddr != null) {
        _selectAddress(defaultAddr);
      } else if (addresses.isNotEmpty) {
        _selectAddress(addresses.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAddresses = false);
    }
  }

  void _selectAddress(CustomerAddressModel addr) {
    setState(() {
      _selectedAddress = addr;
      _addressController.text = _buildAddressText(addr);
    });
    _calculateShipping(addr.province);
  }

  String _buildAddressText(CustomerAddressModel addr) {
    final parts = [
      addr.address,
      if (addr.ward != null) addr.ward,
      addr.district,
      addr.province,
    ].whereType<String>();
    return parts.join(', ');
  }

  Future<void> _calculateShipping(String toProvince) async {
    try {
      const fromProvince = 'Thành phố Hồ Chí Minh';
      final cartState = context.read<CartBloc>().state;
      final items = _selectedIds == null || _selectedIds!.isEmpty
          ? cartState.items
          : cartState.items.where((i) => _selectedIds!.contains(i.id)).toList();
      final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);

      final fee = await _shippingService.calculateShippingFee(
        fromProvince: fromProvince,
        toProvince: toProvince,
        subtotal: subtotal,
      );
      if (!mounted) return;
      setState(() => _shippingFee = fee);
    } catch (e) {
      if (!mounted) return;
      setState(() => _shippingFee = AppConfig.flatShippingFee);
    }
  }

  Future<void> _applyPromoCode(double subtotal) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _applyingPromo = true;
      _promoError = null;
    });

    try {
      final discount = await _voucherService.validate(code, subtotal);
      if (!mounted) return;
      setState(() {
        _discountAmount = discount;
        _promoCode = code;
        _promoError = null;
        _applyingPromo = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _discountAmount = 0;
        _promoCode = null;
        _promoError = e.message;
        _applyingPromo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _discountAmount = 0;
        _promoCode = null;
        _promoError = 'Áp dụng mã giảm giá thất bại. Vui lòng thử lại.';
        _applyingPromo = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dịch vụ vị trí đang tắt. Vui lòng bật trong cài đặt.'),
          ),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng bật quyền vị trí trong cài đặt'),
          ),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      _latitude = position.latitude;
      _longitude = position.longitude;

      final address = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (address != null && address.isNotEmpty) {
        _addressController.text = address;
        setState(() => _selectedAddress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lấy vị trí thành công',
                style: TextStyle(color: AppColors.onPrimary)),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _addressController.text =
            'Vĩ độ: ${position.latitude.toStringAsFixed(6)}, Kinh độ: ${position.longitude.toStringAsFixed(6)}';
        setState(() => _selectedAddress = null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy vị trí: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=vi&countrycodes=vn',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'BigStyle/1.0 (bigstyle-app)'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Thanh toán')),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state.awaitingPayment) {
            final authState = context.read<AuthBloc>().state;
            Navigator.pushNamed(
              context,
              '/payment-qr',
              arguments: PaymentQrArgs(
                orderId: state.orderId!,
                orderNumber: state.orderNumber,
                total: state.total ?? 0,
                userId: authState.user?.id ?? '',
                selectedIds: _selectedIds,
              ),
            );
          } else if (state.isSuccess) {
            final authState = context.read<AuthBloc>().state;
            final userId = authState.user?.id;
            if (userId != null) {
              for (final id in (_selectedIds ?? <String>[])) {
                context.read<CartBloc>().add(CartRemoveItem(id));
              }
            }
            Haptics.success();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AnimatedSuccessCheck(size: 64),
                    const SizedBox(height: 16),
                    Text('Đặt hàng thành công!', style: AppTypography.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Mã đơn hàng: ${state.orderNumber ?? state.orderId?.substring(0, 8)}',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Xem đơn hàng',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacementNamed(
                          '/order-detail',
                          arguments: state.orderId,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Đóng',
                      isOutlined: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.error != null) {
            final canRetryPayment =
                state.orderId != null &&
                state.error == 'Tạo yêu cầu thanh toán thất bại. Vui lòng thử lại.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                action: canRetryPayment
                    ? SnackBarAction(
                        label: 'Thử lại',
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          context.read<CheckoutBloc>().add(
                            CheckoutRetryPayment(
                              orderId: state.orderId!,
                              userId: authState.user?.id ?? '',
                              orderNumber: state.orderNumber,
                              total: state.total ?? 0,
                            ),
                          );
                        },
                      )
                    : null,
              ),
            );
          }
        },
        builder: (context, checkoutState) {
          return BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final items = _selectedIds == null || _selectedIds!.isEmpty
                  ? cartState.items
                  : cartState.items.where((i) => _selectedIds!.contains(i.id)).toList();
              final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
              final total = subtotal + _shippingFee - _discountAmount;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddressSection(),
                      const SizedBox(height: 24),
                      CheckoutItemList(items: items),
                      const SizedBox(height: 24),
                      Text('Ghi chú', style: AppTypography.headlineSmall),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _noteController,
                        hint: 'Ghi chú cho đơn hàng (không bắt buộc)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Text('Phương thức thanh toán', style: AppTypography.headlineSmall),
                      const SizedBox(height: 12),
                      CheckoutPaymentMethodSelector(
                        value: _paymentMethod,
                        onChanged: (value) => setState(() => _paymentMethod = value),
                      ),
                      const SizedBox(height: 24),
                      CheckoutVoucherField(
                        controller: _promoController,
                        isLoading: _applyingPromo,
                        errorText: _promoError,
                        onApply: () => _applyPromoCode(subtotal),
                      ),
                      const SizedBox(height: 24),
                      CheckoutPriceSummary(
                        subtotal: subtotal,
                        shippingFee: _shippingFee,
                        discountAmount: _discountAmount,
                        total: total,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Đặt hàng (${formatVnd(total)})',
                        isLoading: checkoutState.isLoading,
                        onPressed: _placeOrder,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Địa chỉ giao hàng', style: AppTypography.headlineSmall),
            TextButton.icon(
              onPressed: _isLoadingLocation
                  ? null
                  : () => _showLocationDialog(),
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 16),
              label: Text(_isLoadingLocation ? 'Đang lấy...' : 'Vị trí hiện tại',
                  style: AppTypography.caption),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingAddresses)
          const Center(child: CircularProgressIndicator())
        else if (_savedAddresses.isEmpty)
          _buildManualAddressInput()
        else ...[
          ..._savedAddresses.map((addr) => _buildAddressRadio(addr)),
          const SizedBox(height: 8),
          _buildManualAddressInput(),
        ],
      ],
    );
  }

  Widget _buildAddressRadio(CustomerAddressModel addr) {
    final isSelected = _selectedAddress?.id == addr.id;
    return GestureDetector(
      onTap: () => _selectAddress(addr),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<CustomerAddressModel>(
              value: addr,
              groupValue: _selectedAddress,
              onChanged: (v) => _selectAddress(addr),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(addr.label,
                            style: AppTypography.caption.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      if (addr.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Mặc định',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.success, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${addr.fullName}${addr.phone != null ? ' - ${addr.phone}' : ''}',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_buildAddressText(addr),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualAddressInput() {
    return Column(
      children: [
        AppTextField(
          controller: _addressController,
          hint: 'Nhập địa chỉ giao hàng',
          prefixIcon: const Icon(Icons.location_on_outlined),
          maxLines: 2,
          onChanged: (_) => setState(() => _selectedAddress = null),
        ),
        const SizedBox(height: 6),
        Text(
          '* Tỉnh/Thành phố sẽ được dùng để tính phí vận chuyển',
          style: AppTypography.caption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Future<void> _showLocationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Sử dụng vị trí hiện tại', style: AppTypography.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Bạn muốn mở vị trí khi sử dụng app để tự động điền địa chỉ giao hàng?',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cho phép'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) _getCurrentLocation();
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (user == null || user.id.isEmpty || user.id.startsWith('mock-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng')),
      );
      return;
    }

    final cartState = context.read<CartBloc>().state;
    final items = _selectedIds == null || _selectedIds!.isEmpty
        ? cartState.items
        : cartState.items.where((i) => _selectedIds!.contains(i.id)).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm để đặt hàng')),
      );
      return;
    }

    final addressText = _addressController.text.trim();
    if (addressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ giao hàng')),
      );
      return;
    }

    final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);

    context.read<CheckoutBloc>().add(
      CheckoutPlaceOrder(
        userId: user.id,
        items: items,
        subtotal: subtotal,
        shippingFee: _shippingFee,
        address: addressText,
        latitude: _latitude ?? _selectedAddress?.latitude,
        longitude: _longitude ?? _selectedAddress?.longitude,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        customerEmail: user.email.isNotEmpty ? user.email : null,
        paymentMethod: _paymentMethod,
        promoCode: _promoCode,
      ),
    );
  }
}
