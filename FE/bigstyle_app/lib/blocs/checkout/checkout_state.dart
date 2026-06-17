import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final double shippingFee;
  final String? orderId;
  final String? error;

  const CheckoutState({
    this.isLoading = false,
    this.isSuccess = false,
    this.shippingFee = 0,
    this.orderId,
    this.error,
  });

  CheckoutState copyWith({
    bool? isLoading,
    bool? isSuccess,
    double? shippingFee,
    String? orderId,
    String? error,
  }) =>
      CheckoutState(
        isLoading: isLoading ?? this.isLoading,
        isSuccess: isSuccess ?? this.isSuccess,
        shippingFee: shippingFee ?? this.shippingFee,
        orderId: orderId ?? this.orderId,
        error: error,
      );

  @override
  List<Object?> get props =>
      [isLoading, isSuccess, shippingFee, orderId, error];
}
