import 'package:bigstyle_app/screens/auth/otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<GlobalKey<OtpInputState>> pumpOtp(
    WidgetTester tester, {
    required List<String> captured,
    bool enabled = true,
  }) async {
    final key = GlobalKey<OtpInputState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: OtpInput(
              key: key,
              enabled: enabled,
              onResend: () {},
              onCompleted: captured.add,
            ),
          ),
        ),
      ),
    );
    return key;
  }

  Finder box(int i) => find.byType(TextField).at(i);

  testWidgets('pasting a clean 6-digit code fills all boxes and submits once', (
    tester,
  ) async {
    final captured = <String>[];
    await pumpOtp(tester, captured: captured);

    await tester.enterText(box(0), '123456');
    await tester.pump();

    expect(captured, ['123456']);
  });

  testWidgets('pasting a noisy clipboard extracts the standalone 6-digit run', (
    tester,
  ) async {
    final captured = <String>[];
    await pumpOtp(tester, captured: captured);

    await tester.enterText(box(0), '10/07/2026 — mã: 483920');
    await tester.pump();

    expect(captured, ['483920']);
  });

  testWidgets('pasting fewer than 6 digits is ignored, no submit', (
    tester,
  ) async {
    final captured = <String>[];
    await pumpOtp(tester, captured: captured);

    await tester.enterText(box(0), '12ab');
    await tester.pump();

    expect(captured, isEmpty);
    expect(tester.widget<TextField>(box(0)).controller!.text, '');
  });

  testWidgets('editing a middle box after all filled re-submits (G15)', (
    tester,
  ) async {
    final captured = <String>[];
    await pumpOtp(tester, captured: captured);

    for (var i = 0; i < 6; i++) {
      await tester.enterText(box(i), '${i + 1}');
      await tester.pump();
    }
    expect(captured.last, '123456');

    await tester.enterText(box(2), '');
    await tester.pump();
    await tester.enterText(box(2), '9');
    await tester.pump();

    expect(captured.last, '129456');
    expect(captured.length, 2);
  });

  testWidgets('re-entering the identical code after clear() re-submits', (
    tester,
  ) async {
    final captured = <String>[];
    final key = await pumpOtp(tester, captured: captured);

    await tester.enterText(box(0), '123456');
    await tester.pump();
    expect(captured, ['123456']);

    key.currentState!.clear();
    await tester.pump();

    await tester.enterText(box(0), '123456');
    await tester.pump();

    expect(captured, ['123456', '123456']);
  });

  testWidgets('backspace on an empty box clears and focuses the previous (G13)',
      (tester) async {
    final captured = <String>[];
    await pumpOtp(tester, captured: captured);

    await tester.enterText(box(2), '5');
    await tester.pump();
    // Focus advanced to the empty box 3.
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(tester.widget<TextField>(box(2)).controller!.text, '');
  });

  testWidgets('enabled: false disables every box', (tester) async {
    final captured = <String>[];
    await pumpOtp(tester, captured: captured, enabled: false);

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.length, 6);
    for (final f in fields) {
      expect(f.enabled, isFalse);
    }
  });
}
