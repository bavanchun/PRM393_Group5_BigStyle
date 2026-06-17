import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSendOtp extends AuthEvent {
  final String email;
  const AuthSendOtp(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthVerifyOtp extends AuthEvent {
  final String email;
  final String otp;
  const AuthVerifyOtp(this.email, this.otp);

  @override
  List<Object?> get props => [email, otp];
}

class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}

class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}

class AuthUpdateProfile extends AuthEvent {
  final UserModel user;
  const AuthUpdateProfile(this.user);

  @override
  List<Object?> get props => [user];
}
