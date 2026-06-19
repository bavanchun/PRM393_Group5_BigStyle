import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SendOTPEvent extends AuthEvent {
  final String email;
  const SendOTPEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class VerifyOTPEvent extends AuthEvent {
  final String email;
  final String otp;
  const VerifyOTPEvent(this.email, this.otp);

  @override
  List<Object?> get props => [email, otp];
}

class GoogleSignInEvent extends AuthEvent {
  const GoogleSignInEvent();
}

class CheckSessionEvent extends AuthEvent {
  const CheckSessionEvent();
}

class MockLoginEvent extends AuthEvent {
  final String role;
  const MockLoginEvent(this.role);

  @override
  List<Object?> get props => [role];
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class UpdateProfileEvent extends AuthEvent {
  final UserModel user;
  const UpdateProfileEvent(this.user);

  @override
  List<Object?> get props => [user];
}
