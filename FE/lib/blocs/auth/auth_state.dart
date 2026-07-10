import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

class AuthState extends Equatable {
  final UserModel? user;
  final String? error;

  const AuthState({this.user, this.error});

  bool get isInitial => user == null && error == null;
  bool get isLoading => false;
  bool get isOTPSent => false;
  bool get isAuthenticated => user != null;

  @override
  List<Object?> get props => [user, error];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Session check finished and no authenticated user was found.
///
/// Distinct from [AuthInitial] so emitting it from the initial state always
/// produces a real transition — Equatable compares runtimeType first, so a
/// re-emitted [AuthInitial] would be deduped and the splash listener would
/// never fire (the guest splash-hang bug).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthOTPSent extends AuthState {
  final String email;
  const AuthOTPSent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthSuccess extends AuthState {
  const AuthSuccess(UserModel user) : super(user: user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message) : super(error: message);

  @override
  List<Object?> get props => [message];
}

/// Sign-up succeeded but requires email confirmation before a session exists
/// (hosted "Confirm email" ON). Defensive path — the demo turns confirmations
/// OFF, but the code still handles it.
class AuthSignUpConfirmationPending extends AuthState {
  const AuthSignUpConfirmationPending();
}
