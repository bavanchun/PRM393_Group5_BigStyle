import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderLoad extends OrderEvent {
  final String userId;
  const OrderLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

class OrderLoadDetail extends OrderEvent {
  final String orderId;
  const OrderLoadDetail(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
