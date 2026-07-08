import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_config.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/payment/payment_event.dart';
import '../../blocs/payment/payment_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../services/payment_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// Navigation arguments for '/payment-qr'.
class PaymentQrArgs {
  final String orderId;
  final String? orderNumber;
  final double total;
  final String userId;
  final List<String>? selectedIds;
  // Whether completing this payment should clear the user's cart. True for a
  // fresh checkout; false when re-paying an old pending order (that order's
  // items are long gone from the cart — don't wipe items added since).
  final bool clearCartOnPaid;

  const PaymentQrArgs({
    required this.orderId,
    required this.orderNumber,
    required this.total,
    required this.userId,
    this.selectedIds,
    this.clearCartOnPaid = true,
  });
}

class PaymentQrScreen extends StatefulWidget {
  const PaymentQrScreen({super.key});

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  final _paymentService = PaymentService();
  PaymentQrArgs? _args;
  bool _watchStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_watchStarted) {
      final args =
          ModalRoute.of(context)?.settings.arguments as PaymentQrArgs?;
      if (args != null) {
        _args = args;
        _watchStarted = true;
        context
            .read<PaymentBloc>()
            .add(PaymentWatchStarted(args.orderId, args.userId));
      }
    }
  }

  @override
  void dispose() {
    context.read<PaymentBloc>().add(const PaymentWatchStopped());
    super.dispose();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return const Scaffold(
        body: Center(child: Text('Thiếu thông tin đơn hàng')),
      );
    }

    final orderNumber = args.orderNumber ?? args.orderId.substring(0, 8);
    final amountText = args.total.toInt().toString();

    if (kDebugMode &&
        (AppConfig.sepayBank.isEmpty || AppConfig.sepayAcc.isEmpty)) {
      debugPrint(
        'PaymentQrScreen: SEPAY_BANK/SEPAY_ACC missing in .env — QR image will fail.',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Thanh toán chuyển khoản')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state.isPaid) {
            // Payment confirmed — remove only the checked-out items so
            // unselected cart items survive. Skip for re-payment of an old
            // order so the current cart isn't wiped.
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
            _showSuccessDialog(context);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Quét mã QR để chuyển khoản',
                  style: AppTypography.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      child: Image.network(
                        _paymentService.buildQrUrl(args.total, orderNumber),
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 260,
                            height: 260,
                            alignment: Alignment.center,
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'Không tải được mã QR.\nVui lòng dùng thông tin chuyển khoản bên dưới.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Thông tin chuyển khoản', style: AppTypography.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      _buildCopyRow('Ngân hàng', AppConfig.sepayBank),
                      const Divider(height: AppSpacing.lg),
                      _buildCopyRow('Số tài khoản', AppConfig.sepayAcc),
                      const Divider(height: AppSpacing.lg),
                      _buildCopyRow('Số tiền', '$amountText' 'đ'),
                      const Divider(height: AppSpacing.lg),
                      _buildCopyRow('Nội dung chuyển khoản', orderNumber),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Vui lòng nhập đúng nội dung chuyển khoản để hệ thống tự động xác nhận đơn hàng.',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Kiểm tra thanh toán',
                  isLoading: state.isChecking,
                  onPressed: () => context
                      .read<PaymentBloc>()
                      .add(PaymentCheckRequested(args.orderId)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Quay lại',
                  isOutlined: true,
                  onPressed: () {
                    context.read<PaymentBloc>().add(const PaymentWatchStopped());
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, color: AppColors.primary),
          onPressed: value.isEmpty ? null : () => _copy(label, value),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
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
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text('Thanh toán thành công!', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Đơn hàng đã được xác nhận.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Xem đơn hàng',
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/orders', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
