import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/widgets/app_error_state.dart';

void main() {
  testWidgets('AppErrorState renders message and retry action', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Không tải được dữ liệu',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('Không tải được dữ liệu'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    expect(retryCount, 1);
  });
}
