import 'package:equatable/equatable.dart';

sealed class ManagerEvent extends Equatable {
  const ManagerEvent();

  @override
  List<Object?> get props => [];
}

class ManagerLoadDashboard extends ManagerEvent {
  const ManagerLoadDashboard();
}

class ManagerLoadOrders extends ManagerEvent {
  final String? status;

  const ManagerLoadOrders({this.status});

  @override
  List<Object?> get props => [status];
}
