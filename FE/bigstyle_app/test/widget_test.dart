import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/main.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BigStyleApp());
    expect(find.text('BigStyle'), findsOneWidget);
  });
}
