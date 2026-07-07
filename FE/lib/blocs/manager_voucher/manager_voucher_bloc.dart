import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/voucher_service.dart';
import 'manager_voucher_event.dart';
import 'manager_voucher_state.dart';

class ManagerVoucherBloc extends Bloc<ManagerVoucherEvent, ManagerVoucherState> {
  final VoucherService _voucherService;

  ManagerVoucherBloc(this._voucherService) : super(ManagerVoucherInitial()) {
    on<LoadManagerVouchersEvent>(_onLoad);
    on<CreateManagerVoucherEvent>(_onCreate);
    on<UpdateManagerVoucherEvent>(_onUpdate);
    on<ToggleManagerVoucherActiveEvent>(_onToggleActive);
  }

  Future<void> _onLoad(
      LoadManagerVouchersEvent event, Emitter<ManagerVoucherState> emit) async {
    emit(ManagerVoucherLoading());
    try {
      final vouchers = await _voucherService.getVouchersForManager();
      emit(ManagerVoucherLoaded(vouchers));
    } catch (e) {
      emit(ManagerVoucherError(e.toString()));
    }
  }

  Future<void> _onCreate(
      CreateManagerVoucherEvent event, Emitter<ManagerVoucherState> emit) async {
    try {
      final created = await _voucherService.createVoucher(event.voucher);
      if (created != null) {
        emit(const ManagerVoucherOperationSuccess('Tạo mã giảm giá thành công!'));
        add(LoadManagerVouchersEvent());
      } else {
        emit(const ManagerVoucherError('Lỗi khi tạo mã giảm giá'));
      }
    } catch (e) {
      emit(ManagerVoucherError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateManagerVoucherEvent event, Emitter<ManagerVoucherState> emit) async {
    try {
      final updated = await _voucherService.updateVoucher(event.voucher);
      if (updated != null) {
        emit(const ManagerVoucherOperationSuccess('Cập nhật mã giảm giá thành công!'));
        add(LoadManagerVouchersEvent());
      } else {
        emit(const ManagerVoucherError('Lỗi khi cập nhật mã giảm giá'));
      }
    } catch (e) {
      emit(ManagerVoucherError(e.toString()));
    }
  }

  Future<void> _onToggleActive(ToggleManagerVoucherActiveEvent event,
      Emitter<ManagerVoucherState> emit) async {
    try {
      await _voucherService.setActive(event.id, event.isActive);
      emit(ManagerVoucherOperationSuccess(
        event.isActive ? 'Đã bật mã giảm giá!' : 'Đã tắt mã giảm giá!',
      ));
      add(LoadManagerVouchersEvent());
    } catch (e) {
      emit(ManagerVoucherError(e.toString()));
    }
  }
}
