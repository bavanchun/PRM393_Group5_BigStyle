import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _EmptyGotrueAsyncStorage(),
      ),
    );
  });

  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BigStyleApp());
    expect(find.text('BigStyle'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}

class _EmptyGotrueAsyncStorage extends GotrueAsyncStorage {
  const _EmptyGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
