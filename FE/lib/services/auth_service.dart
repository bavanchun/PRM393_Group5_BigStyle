import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<UserModel?> get userStream {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;
      return _fetchUser(event.session!.user.id);
    });
  }

  Future<UserModel?> _fetchUser(String userId) async {
    try {
      final data = await _client.from('profiles').select().eq('id', userId).single();
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
    final response =
        await _client.auth.verifyOTP(email: email, token: otp, type: OtpType.email);
    final user = response.user;
    if (user == null) return null;

    final existing = _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (await existing == null) {
      // Profile is already created by database trigger, update with name
      await _client.from('profiles').update({
        'full_name': email.split('@').first,
      }).eq('id', user.id);
    }
    return _fetchUser(user.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
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
