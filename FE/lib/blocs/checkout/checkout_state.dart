import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final double shippingFee;
  final String? orderId;
  final String? error;
  // bank_transfer branch: order + pending payment created, waiting on /payment-qr.
  final bool awaitingPayment;
  final String? orderNumber;
  final double? total;

  const CheckoutState({
    this.isLoading = false,
    this.isSuccess = false,
    this.shippingFee = 0,
    this.orderId,
    this.error,
    this.awaitingPayment = false,
    this.orderNumber,
    this.total,
  });

  CheckoutState copyWith({
    bool? isLoading,
    bool? isSuccess,
    double? shippingFee,
    String? orderId,
    String? error,
    bool? awaitingPayment,
    String? orderNumber,
    double? total,
  }) =>
      CheckoutState(
        isLoading: isLoading ?? this.isLoading,
        isSuccess: isSuccess ?? this.isSuccess,
        shippingFee: shippingFee ?? this.shippingFee,
        orderId: orderId ?? this.orderId,
        error: error,
        awaitingPayment: awaitingPayment ?? this.awaitingPayment,
        orderNumber: orderNumber ?? this.orderNumber,
        total: total ?? this.total,
      );

  @override
  List<Object?> get props => [
        isLoading,
        isSuccess,
        shippingFee,
        orderId,
        error,
        awaitingPayment,
        orderNumber,
        total,
      ];
}
