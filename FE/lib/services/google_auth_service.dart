import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
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
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': googleUser.displayName ?? user.email!.split('@').first,
        'avatar_url': googleUser.photoUrl,
        'role': 'customer',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromMap(data);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
