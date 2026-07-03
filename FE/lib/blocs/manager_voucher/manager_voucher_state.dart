import 'package:equatable/equatable.dart';
import '../../models/voucher_model.dart';

abstract class ManagerVoucherState extends Equatable {
  const ManagerVoucherState();

  @override
  List<Object?> get props => [];
}

class ManagerVoucherInitial extends ManagerVoucherState {}

class ManagerVoucherLoading extends ManagerVoucherState {}

class ManagerVoucherLoaded extends ManagerVoucherState {
  final List<VoucherModel> vouchers;

  const ManagerVoucherLoaded(this.vouchers);

  @override
  List<Object?> get props => [vouchers];
}

class ManagerVoucherOperationSuccess extends ManagerVoucherState {
  final String message;

  const ManagerVoucherOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ManagerVoucherError extends ManagerVoucherState {
  final String error;

  const ManagerVoucherError(this.error);

  @override
  List<Object?> get props => [error];
}
