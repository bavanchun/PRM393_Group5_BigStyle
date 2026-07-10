import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/config/theme/app_colors.dart';
import 'package:bigstyle_app/config/theme/app_theme.dart';
import 'package:bigstyle_app/config/theme/status_colors.dart';
import 'package:bigstyle_app/models/order_status.dart';
import 'package:bigstyle_app/widgets/status_badge.dart';

Color _renderedTextColor(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text));
  return text.style!.color!;
}

Future<void> _pump(WidgetTester tester, OrderStatus status) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: StatusBadge(label: status.label, status: status),
    ),
  ));
}

void main() {
  final statusColors = StatusColors.standard;

  testWidgets('pending resolves to warning tone', (tester) async {
    await _pump(tester, OrderStatus.pending);
    expect(_renderedTextColor(tester), statusColors.warning);
  });

  testWidgets('confirmed resolves to brand primary tone', (tester) async {
    await _pump(tester, OrderStatus.confirmed);
    expect(_renderedTextColor(tester), AppColors.primary);
  });

  testWidgets('shipping resolves to info tone (not a raw Colors.blue)',
      (tester) async {
    await _pump(tester, OrderStatus.shipping);
    expect(_renderedTextColor(tester), statusColors.info);
    expect(_renderedTextColor(tester), isNot(Colors.blue));
  });

  testWidgets('delivered resolves to success tone', (tester) async {
    await _pump(tester, OrderStatus.delivered);
    expect(_renderedTextColor(tester), statusColors.success);
  });

  testWidgets('cancelled resolves to error tone', (tester) async {
    await _pump(tester, OrderStatus.cancelled);
    expect(_renderedTextColor(tester), statusColors.error);
  });

  testWidgets('renders tonal (tinted bg), never solid-fill + white text',
      (tester) async {
    await _pump(tester, OrderStatus.delivered);
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(_renderedTextColor(tester), isNot(Colors.white));
    expect(decoration.color, isNot(statusColors.success));
    expect(decoration.color!.a, lessThan(1.0));
  });
}
