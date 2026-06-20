import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;

  AuthBloc(this._authService, this._googleAuthService)
    : super(const AuthInitial()) {
    on<CheckSessionEvent>(_onCheckSession);
    on<SendOTPEvent>(_onSendOtp);
    on<VerifyOTPEvent>(_onVerifyOtp);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<MockLoginEvent>(_onMockLogin);
    on<SignOutEvent>(_onSignOut);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onCheckSession(
    CheckSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(const AuthInitial());
    }
  }

  Future<void> _onSendOtp(SendOTPEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authService.sendOtp(event.email);
      emit(AuthOTPSent(event.email));
    } catch (e) {
      emit(AuthError('Gửi mã OTP thất bại: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOTPEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.verifyOtp(event.email, event.otp);
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthError('Mã OTP không hợp lệ'));
      }
    } catch (_) {
      emit(const AuthError('Xác thực thất bại'));
    }
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _googleAuthService.signInWithGoogle();
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthError('Đăng nhập Google thất bại'));
      }
    } catch (_) {
      emit(const AuthError('Đăng nhập Google thất bại'));
    }
  }

  Future<void> _onMockLogin(
    MockLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (kReleaseMode) return;

    emit(const AuthLoading());
    final user = UserModel(
      id: event.role == 'manager' ? 'mock-manager-id' : 'mock-user-id',
      email: event.role == 'manager'
          ? 'manager@bigstyle.com'
          : 'user@bigstyle.com',
      fullName: event.role == 'manager' ? 'Quản lý BigStyle' : 'Nguyễn Văn A',
      phone: '0123456789',
      role: event.role == 'manager' ? UserRole.manager : UserRole.customer,
      createdAt: DateTime.now(),
    );
    emit(AuthSuccess(user));
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(const AuthInitial());
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.updateProfile(event.user);
      emit(AuthSuccess(event.user));
    } catch (_) {
      emit(const AuthError('Cập nhật thất bại'));
    }
  }
}
