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

class PasswordSignInEvent extends AuthEvent {
  final String email;
  final String password;
  const PasswordSignInEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email];
}

class PasswordSignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  const PasswordSignUpEvent({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, fullName];
}

class CheckSessionEvent extends AuthEvent {
  const CheckSessionEvent();
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
