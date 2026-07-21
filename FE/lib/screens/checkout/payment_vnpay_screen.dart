import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/payment/payment_event.dart';
import '../../blocs/payment/payment_state.dart';
import '../../config/app_config.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../services/vnpay_service.dart';
import '../../widgets/app_button.dart';

class PaymentVnpayArgs {
  const PaymentVnpayArgs({
    required this.orderId,
    required this.orderNumber,
    required this.total,
    required this.userId,
    this.selectedIds,
    this.clearCartOnPaid = true,
  });

  final String orderId;
  final String? orderNumber;
  final double total;
  final String userId;
  final List<String>? selectedIds;
  final bool clearCartOnPaid;
}

class PaymentVnpayScreen extends StatefulWidget {
  const PaymentVnpayScreen({super.key});

  @override
  State<PaymentVnpayScreen> createState() => _PaymentVnpayScreenState();
}

class _PaymentVnpayScreenState extends State<PaymentVnpayScreen> {
  final _vnpayService = VnpayService();

  PaymentVnpayArgs? _args;
  bool _bootstrapped = false;
  bool _isLoadingUrl = true;
  bool _handledResult = false;
  String? _error;
  Timer? _timeoutTimer;

  static const _vnpayLoadTimeout = Duration(minutes: 5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as PaymentVnpayArgs?;
    if (args == null) {
      setState(() {
        _error = 'Thiếu thông tin đơn hàng';
        _isLoadingUrl = false;
      });
      _bootstrapped = true;
      return;
    }
    _args = args;
    _bootstrapped = true;
    context
        .read<PaymentBloc>()
        .add(PaymentWatchStarted(args.orderId, args.userId));
    _startPayment(args);
  }

  Future<void> _openVnpayInAppBrowser(String url) async {
    final browser = ChromeSafariBrowser();
    await browser.open(url: WebUri(url));
  }

  Future<void> _startPayment(PaymentVnpayArgs args) async {
    _timeoutTimer?.cancel();
    setState(() {
      _isLoadingUrl = true;
      _error = null;
      _handledResult = false;
    });
    try {
      final result = await _vnpayService.createPayment(
        orderId: args.orderId,
        amount: args.total,
        orderNumber: args.orderNumber,
        returnUrl: AppConfig.vnpayReturnUrl,
      );
      if (!mounted) return;
      dev.log('VNPay URL: ${result.paymentUrl}', name: 'VnpayScreen');

      await _openVnpayInAppBrowser(result.paymentUrl);

      setState(() {
        _isLoadingUrl = false;
      });

      _timeoutTimer = Timer(_vnpayLoadTimeout, () {
        if (mounted && !_handledResult && _error == null) {
          setState(() {
            _error = null;
          });
        }
      });
    } catch (e) {
      dev.log('VNPay createPayment failed: $e', name: 'VnpayScreen');
      _timeoutTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isLoadingUrl = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onPaid(PaymentVnpayArgs args) {
    if (_handledResult) return;
    _handledResult = true;

    if (args.clearCartOnPaid) {
      final ids = args.selectedIds;
      if (ids != null && ids.isNotEmpty) {
        for (final id in ids) {
          context.read<CartBloc>().add(CartRemoveItem(id));
        }
      } else {
        context.read<CartBloc>().add(CartClear(args.userId));
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text('Thanh toán thành công!', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Mã đơn hàng: ${args.orderNumber ?? args.orderId.substring(0, 8)}',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Xem đơn hàng',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/order-detail',
                  (route) => route.isFirst,
                  arguments: args.orderId,
                );
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Về trang chủ',
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

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    context.read<PaymentBloc>().add(const PaymentWatchStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state.isPaid && args != null) {
            _onPaid(args);
          }
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, paymentState) {
          if (_isLoadingUrl) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Thử lại',
                    onPressed: args == null ? null : () => _startPayment(args),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Quay lại',
                    isOutlined: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded,
                      color: AppColors.primary, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Hoàn tất thanh toán',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trình duyệt thanh toán đã được đóng. Quay lại đây để kiểm tra trạng thái.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: paymentState.isChecking
                        ? 'Đang kiểm tra...'
                        : 'Kiểm tra thanh toán',
                    isLoading: paymentState.isChecking,
                    onPressed: args == null || paymentState.isChecking
                        ? null
                        : () {
                            context.read<PaymentBloc>().add(
                                  PaymentCheckRequested(args.orderId),
                                );
                          },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Huỷ',
                    isOutlined: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
