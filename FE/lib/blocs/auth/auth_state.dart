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
