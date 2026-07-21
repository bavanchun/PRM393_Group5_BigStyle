import 'dart:async';

import 'package:bigstyle_app/blocs/auth/auth_bloc.dart';
import 'package:bigstyle_app/blocs/auth/auth_event.dart';
import 'package:bigstyle_app/blocs/auth/auth_state.dart';
import 'package:bigstyle_app/models/user_model.dart';
import 'package:bigstyle_app/services/auth_service.dart';
import 'package:bigstyle_app/services/google_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthService extends AuthService {
  FakeAuthService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  UserModel? signInResult;
  Object? signInError;

  SignUpResult? signUpResult;
  Object? signUpError;
  Completer<void>? signUpGate; // if set, first call awaits it (droppable test)
  int signUpCallCount = 0;

  Object? sendPasswordResetError;
  int sendPasswordResetCallCount = 0;

  UserModel? updatePasswordUser;
  Object? updatePasswordError;

  @override
  Future<UserModel?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final error = signInError;
    if (error != null) throw error;
    return signInResult;
  }

  @override
  Future<SignUpResult> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    signUpCallCount++;
    if (signUpGate != null) await signUpGate!.future;
    final error = signUpError;
    if (error != null) throw error;
    return signUpResult ?? const SignUpResult(SignUpOutcome.confirmationPending);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    sendPasswordResetCallCount++;
    final error = sendPasswordResetError;
    if (error != null) throw error;
  }

  @override
  Future<void> updatePassword(String password) async {
    final error = updatePasswordError;
    if (error != null) throw error;
  }

  @override
  Future<UserModel?> getCurrentUser() async => updatePasswordUser;
}

class FakeGoogleAuthService extends GoogleAuthService {
  FakeGoogleAuthService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));
}

UserModel _user() => UserModel(
      id: 'u1',
      email: 'a@b.com',
      fullName: 'Nguyễn Văn A',
      role: UserRole.customer,
      createdAt: DateTime(2026, 7, 11),
    );

void main() {
  late FakeAuthService auth;
  late AuthBloc bloc;

  setUp(() {
    auth = FakeAuthService();
    bloc = AuthBloc(auth, FakeGoogleAuthService());
  });

  tearDown(() => bloc.close());

  group('Password sign-in', () {
    test('success emits AuthSuccess (no release guard skip)', () async {
      auth.signInResult = _user();
      bloc.add(const PasswordSignInEvent(email: 'a@b.com', password: 'secret'));
      final state = await bloc.stream.firstWhere((s) => s is AuthSuccess);
      expect((state as AuthSuccess).user?.id, 'u1');
    });

    test('wrong password emits AuthError with production copy', () async {
      auth.signInError = const AuthException('Invalid login credentials');
      bloc.add(const PasswordSignInEvent(email: 'a@b.com', password: 'x'));
      final state = await bloc.stream.firstWhere((s) => s is AuthError);
      final msg = (state as AuthError).message;
      expect(msg.toLowerCase().contains('test'), isFalse);
      expect(msg.isNotEmpty, isTrue);
    });
  });

  group('Password sign-up', () {
    test('session outcome emits AuthSuccess', () async {
      auth.signUpResult = SignUpResult(SignUpOutcome.success, _user());
      bloc.add(const PasswordSignUpEvent(
          email: 'a@b.com', password: 'secret', fullName: 'A'));
      final state = await bloc.stream.firstWhere((s) => s is AuthSuccess);
      expect((state as AuthSuccess).user?.id, 'u1');
    });

    test('AuthException user-exists maps to already-registered AuthError',
        () async {
      auth.signUpError = const AuthException('User already registered');
      bloc.add(const PasswordSignUpEvent(
          email: 'a@b.com', password: 'secret', fullName: 'A'));
      final state = await bloc.stream.firstWhere((s) => s is AuthError);
      expect((state as AuthError).message.toLowerCase().contains('đăng ký'),
          isTrue);
    });

    test('fake-user (alreadyRegistered outcome) is AuthError, not pending',
        () async {
      auth.signUpResult = const SignUpResult(SignUpOutcome.alreadyRegistered);
      bloc.add(const PasswordSignUpEvent(
          email: 'a@b.com', password: 'secret', fullName: 'A'));
      final state = await bloc.stream.firstWhere(
        (s) => s is AuthError || s is AuthSignUpConfirmationPending,
      );
      expect(state, isA<AuthError>());
    });

    test('genuine no-session emits AuthSignUpConfirmationPending', () async {
      auth.signUpResult =
          const SignUpResult(SignUpOutcome.confirmationPending);
      bloc.add(const PasswordSignUpEvent(
          email: 'a@b.com', password: 'secret', fullName: 'A'));
      final state = await bloc.stream
          .firstWhere((s) => s is AuthSignUpConfirmationPending);
      expect(state, isA<AuthSignUpConfirmationPending>());
    });

    test('rapid double sign-up drops the second (droppable)', () async {
      auth.signUpGate = Completer<void>();
      auth.signUpResult = SignUpResult(SignUpOutcome.success, _user());

      bloc.add(const PasswordSignUpEvent(
          email: 'a@b.com', password: 'secret', fullName: 'A'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const PasswordSignUpEvent(
          email: 'a@b.com', password: 'secret', fullName: 'A'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      auth.signUpGate!.complete();
      await bloc.stream.firstWhere((s) => s is AuthSuccess);

      expect(auth.signUpCallCount, 1);
    });
  });

  group('Password reset request', () {
    test('success emits AuthPasswordResetEmailSent', () async {
      bloc.add(const PasswordResetRequestEvent('a@b.com'));
      final state = await bloc.stream
          .firstWhere((s) => s is AuthPasswordResetEmailSent);
      expect(state, isA<AuthPasswordResetEmailSent>());
      expect(auth.sendPasswordResetCallCount, 1);
    });

    test('failure emits AuthError', () async {
      auth.sendPasswordResetError = Exception('boom');
      bloc.add(const PasswordResetRequestEvent('a@b.com'));
      final state = await bloc.stream.firstWhere((s) => s is AuthError);
      expect((state as AuthError).message.isNotEmpty, isTrue);
    });
  });

  group('Update password', () {
    test('success refetches the user and emits AuthSuccess', () async {
      auth.updatePasswordUser = _user();
      bloc.add(const UpdatePasswordEvent('newSecret1'));
      final state = await bloc.stream.firstWhere((s) => s is AuthSuccess);
      expect((state as AuthSuccess).user?.id, 'u1');
    });

    test('failure emits AuthError', () async {
      auth.updatePasswordError = Exception('boom');
      bloc.add(const UpdatePasswordEvent('newSecret1'));
      final state = await bloc.stream.firstWhere((s) => s is AuthError);
      expect((state as AuthError).message.isNotEmpty, isTrue);
    });

    test('no session after update emits AuthError, not a null-user success',
        () async {
      auth.updatePasswordUser = null;
      bloc.add(const UpdatePasswordEvent('newSecret1'));
      final state = await bloc.stream.firstWhere((s) => s is AuthError);
      expect(state, isA<AuthError>());
    });
  });
}
