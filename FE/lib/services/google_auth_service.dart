import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';

class GoogleAuthService {
  GoogleAuthService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn _initGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: AppConfig.googleWebClientId,
    );
    return _googleSignIn!;
  }

  final SupabaseClient _supabase;

  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _initGoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) return null;

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    final user = response.user;
    if (user == null) return null;

    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      // Profile already created by database trigger, we just need to update it with Google data
      await _supabase.from('profiles').update({
        'full_name': googleUser.displayName ?? user.email!.split('@').first,
        'avatar_url': googleUser.photoUrl,
      }).eq('id', user.id);
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromMap(data);
  }

  Future<void> signOut() async {
    try {
      final googleSignIn = _initGoogleSignIn();
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } catch (_) {}
  }
}
