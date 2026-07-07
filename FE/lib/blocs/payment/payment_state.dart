import 'package:equatable/equatable.dart';

class PaymentState extends Equatable {
  final bool isChecking;
  final bool isPaid;
  final String? error;

  const PaymentState({
    this.isChecking = false,
    this.isPaid = false,
    this.error,
  });

  PaymentState copyWith({
    bool? isChecking,
    bool? isPaid,
    String? error,
  }) =>
      PaymentState(
        isChecking: isChecking ?? this.isChecking,
        isPaid: isPaid ?? this.isPaid,
        error: error,
      );

  @override
  List<Object?> get props => [isChecking, isPaid, error];
}
