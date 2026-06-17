import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

enum AuthStatus { uninitialized, unauthenticated, authenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool otpSent;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.error,
    this.otpSent = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? otpSent,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        otpSent: otpSent ?? this.otpSent,
      );

  @override
  List<Object?> get props => [status, user, error, otpSent];
}
