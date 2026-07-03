import 'package:equatable/equatable.dart';
import '../../models/voucher_model.dart';

abstract class ManagerVoucherEvent extends Equatable {
  const ManagerVoucherEvent();

  @override
  List<Object?> get props => [];
}

class LoadManagerVouchersEvent extends ManagerVoucherEvent {}

class CreateManagerVoucherEvent extends ManagerVoucherEvent {
  final VoucherModel voucher;

  const CreateManagerVoucherEvent(this.voucher);

  @override
  List<Object?> get props => [voucher];
}

class UpdateManagerVoucherEvent extends ManagerVoucherEvent {
  final VoucherModel voucher;

  const UpdateManagerVoucherEvent(this.voucher);

  @override
  List<Object?> get props => [voucher];
}

class ToggleManagerVoucherActiveEvent extends ManagerVoucherEvent {
  final String id;
  final bool isActive;

  const ToggleManagerVoucherActiveEvent(this.id, this.isActive);

  @override
  List<Object?> get props => [id, isActive];
}
