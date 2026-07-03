import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Starts watching payments.status for [orderId] (Realtime + polling).
/// [userId] is needed to clear the cart once payment is confirmed.
class PaymentWatchStarted extends PaymentEvent {
  final String orderId;
  final String userId;
  const PaymentWatchStarted(this.orderId, this.userId);

  @override
  List<Object?> get props => [orderId, userId];
}

/// Internal event fired by the watch subscription when a paid signal arrives.
class PaymentStatusReceived extends PaymentEvent {
  final bool paid;
  const PaymentStatusReceived(this.paid);

  @override
  List<Object?> get props => [paid];
}

/// "Kiểm tra thanh toán" — forces a single on-demand status check.
class PaymentCheckRequested extends PaymentEvent {
  final String orderId;
  const PaymentCheckRequested(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Stops watching (e.g. user taps "Quay lại" or leaves the screen).
class PaymentWatchStopped extends PaymentEvent {
  const PaymentWatchStopped();
}
