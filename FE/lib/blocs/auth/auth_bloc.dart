import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;

  // Drops a second password submit while one is in flight — a double-tap must
  // not race a second auth call (UI button-disable alone is insufficient).
  bool _passwordAuthInFlight = false;

  AuthBloc(this._authService, this._googleAuthService)
    : super(const AuthInitial()) {
    on<CheckSessionEvent>(_onCheckSession);
    on<SendOTPEvent>(_onSendOtp);
    on<VerifyOTPEvent>(_onVerifyOtp);
    on<PasswordSignInEvent>(_onPasswordSignIn);
    on<PasswordSignUpEvent>(_onPasswordSignUp);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<SignOutEvent>(_onSignOut);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onCheckSession(
    CheckSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Emit a loading state first so a repeated failure produces a real
    // AuthError -> AuthLoading -> AuthError transition on retry (identical
    // AuthError messages would otherwise be deduped by Equatable and the
    // splash listener would never fire again).
    emit(const AuthLoading());
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(
        const AuthError(
          'Không thể kiểm tra phiên đăng nhập. Vui lòng thử lại.',
        ),
      );
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

  Future<void> _onPasswordSignIn(
    PasswordSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_passwordAuthInFlight) return;
    _passwordAuthInFlight = true;
    emit(const AuthLoading());
    try {
      final user = await _authService.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthError('Email hoặc mật khẩu không đúng'));
      }
    } catch (_) {
      emit(const AuthError('Email hoặc mật khẩu không đúng'));
    } finally {
      _passwordAuthInFlight = false;
    }
  }

  Future<void> _onPasswordSignUp(
    PasswordSignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_passwordAuthInFlight) return;
    _passwordAuthInFlight = true;
    emit(const AuthLoading());
    try {
      final result = await _authService.signUpWithPassword(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      switch (result.outcome) {
        case SignUpOutcome.success:
          final user = result.user;
          if (user != null) {
            emit(AuthSuccess(user));
          } else {
            emit(const AuthSignUpConfirmationPending());
          }
        case SignUpOutcome.confirmationPending:
          emit(const AuthSignUpConfirmationPending());
        case SignUpOutcome.alreadyRegistered:
          emit(const AuthError('Email đã được đăng ký — hãy đăng nhập'));
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already been registered') ||
          msg.contains('user already')) {
        emit(const AuthError('Email đã được đăng ký — hãy đăng nhập'));
      } else {
        emit(const AuthError('Đăng ký thất bại'));
      }
    } catch (_) {
      emit(const AuthError('Đăng ký thất bại'));
    } finally {
      _passwordAuthInFlight = false;
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
    } catch (e, stackTrace) {
      debugPrint('=== GOOGLE LOGIN ERROR ===');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      emit(const AuthError('Đăng nhập Google thất bại'));
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    await _googleAuthService.signOut();
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
