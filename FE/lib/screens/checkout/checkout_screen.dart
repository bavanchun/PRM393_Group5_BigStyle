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
import '../../services/voucher_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'payment_qr_screen.dart';
import 'widgets/checkout_address_section.dart';
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
  List<String>? _selectedIds;
  // 'cod' | 'bank_transfer'
  String _paymentMethod = 'cod';
  // Vị trí hiện tại
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  // Phí vận chuyển cố định (flat). Dùng chung cho hiển thị và khi đặt hàng để
  // số tiền trên màn khớp với total của đơn tạo ra.
  static const double _shippingFee = AppConfig.flatShippingFee;

  // Promo code preview state — validated client-side for UI feedback only;
  // the create_order RPC re-derives the discount authoritatively.
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
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sử dụng vị trí hiện tại',
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn muốn mở vị trí khi sử dụng app để tự động điền địa chỉ giao hàng?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                        side: BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
    if (confirmed == true) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      // Kiểm tra dịch vụ vị trí có bật không
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dịch vụ vị trí đang tắt. Vui lòng bật trong cài đặt.',
            ),
          ),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Kiểm tra quyền truy cập vị trí
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

      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode
      final address = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (address != null && address.isNotEmpty) {
        _addressController.text = address;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lấy vị trí thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _addressController.text =
            'Vĩ độ: ${position.latitude.toStringAsFixed(6)}, Kinh độ: ${position.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi lấy vị trí: $e')));
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
          // Mutually exclusive: a given place-order result is either a COD
          // success dialog or a SePay QR navigation — never both.
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
            // COD order placed — remove only the checked-out items so
            // unselected cart items survive.
            final authState = context.read<AuthBloc>().state;
            final userId = authState.user?.id;
            if (userId != null) {
              for (final id in (_selectedIds ?? <String>[])) {
                context.read<CartBloc>().add(CartRemoveItem(id));
              }
            }
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
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đặt hàng thành công!',
                      style: AppTypography.headlineMedium,
                    ),
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
                  ],
                ),
              ),
            );
          }
          if (state.error != null) {
            // createOrder succeeded but createPayment failed for the bank
            // transfer branch — orderId/orderNumber survive the error so
            // "Thử lại" can retry only the payment insert, never the order.
            // Gated on the specific message (not just orderId != null) so an
            // order-creation failure never shows a payment-retry action with
            // a stale orderId from a previous order.
            final canRetryPayment =
                state.orderId != null &&
                state.error ==
                    'Tạo yêu cầu thanh toán thất bại. Vui lòng thử lại.';
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
                  : cartState.items
                        .where((i) => _selectedIds!.contains(i.id))
                        .toList();
              final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
              // Preview only — server (create_order RPC) is the source of
              // truth for the persisted subtotal/discount/total.
              final total = subtotal + _shippingFee - _discountAmount;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckoutAddressSection(
                        addressController: _addressController,
                        isLoadingLocation: _isLoadingLocation,
                        onUseCurrentLocation: _showLocationDialog,
                        latitude: _latitude,
                        longitude: _longitude,
                      ),
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
                      Text(
                        'Phương thức thanh toán',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      CheckoutPaymentMethodSelector(
                        value: _paymentMethod,
                        onChanged: (value) {
                          setState(() => _paymentMethod = value);
                        },
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
                        label: 'Đặt hàng (${total.toStringAsFixed(0)}đ)',
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

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    // Auth guard — require a real (non-mock) authenticated user
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

    final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);

    context.read<CheckoutBloc>().add(
      CheckoutPlaceOrder(
        userId: user.id,
        items: items,
        subtotal: subtotal,
        shippingFee: _shippingFee,
        address: _addressController.text,
        latitude: _latitude,
        longitude: _longitude,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        paymentMethod: _paymentMethod,
        promoCode: _promoCode,
      ),
    );
  }
}
