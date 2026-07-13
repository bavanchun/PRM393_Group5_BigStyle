import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

enum SignUpOutcome { success, confirmationPending, alreadyRegistered }

class SignUpResult {
  final SignUpOutcome outcome;
  final UserModel? user;
  const SignUpResult(this.outcome, [this.user]);
}

class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Stream<UserModel?> get userStream {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;
      return _fetchUser(event.session!.user.id);
    });
  }

  Future<UserModel?> _fetchUser(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> sendOtp(String email) async {
    // Code-based OTP: Supabase emails a 6-digit token ({{ .Token }}) that the
    // user types into OtpInput. No deep-link/magic-link redirect is used, so
    // emailRedirectTo is intentionally omitted.
    await _client.auth.signInWithOtp(email: email);
  }

  Future<UserModel?> verifyOtp(String email, String otp) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    final user = response.user;
    if (user == null) return null;
    // full_name is populated by the handle_new_user trigger from signup
    // metadata; no client-side backfill (RLS blocks it in the no-session case).
    return _fetchUser(user.id);
  }

  /// Email+password sign-up. full_name is passed as user metadata so the
  /// handle_new_user trigger writes it into profiles. Distinguishes an
  /// immediate session, a confirmation-pending signup, and the obfuscated
  /// "fake user" Supabase returns when the email already exists (confirmations
  /// ON) — the last must NOT be treated as confirmation-pending.
  Future<SignUpResult> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final user = response.user;
    if (user != null && (user.identities?.isEmpty ?? false)) {
      return const SignUpResult(SignUpOutcome.alreadyRegistered);
    }
    if (response.session != null && user != null) {
      // A session means the user is authenticated. If the profile read lags
      // (RLS race before the trigger commits), fall back to a user built from
      // the known signup data so we emit success, not a false "confirm email".
      final profile = await _fetchUser(user.id);
      return SignUpResult(
        SignUpOutcome.success,
        profile ??
            UserModel(
              id: user.id,
              email: user.email ?? email,
              fullName: fullName,
              role: UserRole.customer,
              createdAt: DateTime.now(),
            ),
      );
    }
    return const SignUpResult(SignUpOutcome.confirmationPending);
  }

  Future<UserModel?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) return null;
    return _fetchUser(user.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sends a password-reset email whose link opens `bigstyle://reset-password`
  /// (a temporary "recovery" session — see main.dart's onAuthStateChange
  /// listener for the AuthChangeEvent.passwordRecovery handling).
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'bigstyle://reset-password',
    );
  }

  /// Sets a new password on the active (recovery) session.
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchUser(user.id);
  }

  Future<void> updateProfile(UserModel user) async {
    await _client.from('profiles').update(user.toMap()).eq('id', user.id);
  }
}
