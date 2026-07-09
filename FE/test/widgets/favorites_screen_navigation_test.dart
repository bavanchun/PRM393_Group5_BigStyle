import 'package:bigstyle_app/blocs/auth/auth_bloc.dart';
import 'package:bigstyle_app/blocs/wishlist/wishlist_bloc.dart';
import 'package:bigstyle_app/screens/favorites/favorites_screen.dart';
import 'package:bigstyle_app/services/auth_service.dart';
import 'package:bigstyle_app/services/google_auth_service.dart';
import 'package:bigstyle_app/services/wishlist_service.dart';
import 'package:bigstyle_app/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthService/GoogleAuthService/WishlistService accept an injectable
/// SupabaseClient (matching OrderService's convention) — a dummy client
/// avoids touching Supabase.instance, which is never initialized in a
/// widget test. FavoritesScreen never dispatches an event that would call
/// these services with a 'mock-' prefixed user id (WishlistBloc._onLoad
/// short-circuits for it), so no method below is ever invoked.
SupabaseClient _dummyClient() => SupabaseClient(
  'http://localhost',
  'anon-key',
  // GoTrueClient starts an auto-refresh Timer on construction by default,
  // which trips flutter_test's "no pending timers" invariant at teardown.
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

void main() {
  testWidgets(
    'Favorites pushed from Profile shows a back button and no bottom nav',
    (tester) async {
      final authBloc = AuthBloc(
        AuthService(client: _dummyClient()),
        GoogleAuthService(client: _dummyClient()),
      );
      final wishlistBloc = WishlistBloc(WishlistService(client: _dummyClient()));
      addTearDown(authBloc.close);
      addTearDown(wishlistBloc.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<WishlistBloc>.value(value: wishlistBloc),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    ),
                    child: const Text('Open Favorites'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Favorites'));
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesScreen), findsNothing);
      expect(find.text('Open Favorites'), findsOneWidget);
    },
  );
}
