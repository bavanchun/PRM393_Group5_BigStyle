import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(const AuthState()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthSendOtp>(_onSendOtp);
    on<AuthVerifyOtp>(_onVerifyOtp);
    on<AuthSignOut>(_onSignOut);
    on<AuthUpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onCheckSession(
      AuthCheckSession event, Emitter<AuthState> emit) async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSendOtp(
      AuthSendOtp event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    try {
      await _authService.sendOtp(event.email);
      emit(state.copyWith(status: AuthStatus.unauthenticated, otpSent: true));
    } catch (e) {
      emit(state.copyWith(
          status: AuthStatus.error, error: 'Gửi mã OTP thất bại'));
    }
  }

  Future<void> _onVerifyOtp(
      AuthVerifyOtp event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));
    try {
      final user = await _authService.verifyOtp(event.email, event.otp);
      if (user != null) {
        emit(state.copyWith(
            status: AuthStatus.authenticated, user: user, otpSent: false));
      } else {
        emit(state.copyWith(
            status: AuthStatus.error, error: 'Mã OTP không hợp lệ'));
      }
    } catch (e) {
      emit(state.copyWith(
          status: AuthStatus.error, error: 'Xác thực thất bại'));
    }
  }

  Future<void> _onSignOut(
      AuthSignOut event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(state.copyWith(
        status: AuthStatus.unauthenticated, user: null, otpSent: false));
  }

  Future<void> _onUpdateProfile(
      AuthUpdateProfile event, Emitter<AuthState> emit) async {
    try {
      await _authService.updateProfile(event.user);
      emit(state.copyWith(user: event.user));
    } catch (e) {
      emit(state.copyWith(error: 'Cập nhật thất bại'));
    }
  }
}
