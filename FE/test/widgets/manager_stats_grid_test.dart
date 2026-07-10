import 'package:bigstyle_app/config/theme/app_colors.dart';
import 'package:bigstyle_app/config/theme/app_theme.dart';
import 'package:bigstyle_app/config/theme/status_colors.dart';
import 'package:bigstyle_app/models/manager_dashboard_stats.dart';
import 'package:bigstyle_app/screens/manager/manager_dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ManagerStatsGrid(
              stats: ManagerDashboardStats(
                todayRevenue: 350000,
                pendingOrderCount: 5,
                productCount: 12,
                customerCount: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('stat value renders in textPrimary, not a per-card accent', (
    tester,
  ) async {
    await pumpGrid(tester);

    final value = tester.widget<Text>(find.text('5'));
    expect(value.style?.color, AppColors.textPrimary);
    expect(value.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('pending card accent is warning, matching StatusBadge mapping', (
    tester,
  ) async {
    await pumpGrid(tester);

    final pendingIcon = tester.widget<Icon>(find.byIcon(Icons.receipt_long));
    expect(pendingIcon.color, AppColors.warning);
  });

  testWidgets('product-count card accent is the info tone, distinct from warning', (
    tester,
  ) async {
    await pumpGrid(tester);

    final productIcon = tester.widget<Icon>(find.byIcon(Icons.inventory_2));
    expect(productIcon.color, StatusColors.standard.info);
    expect(productIcon.color, isNot(AppColors.warning));
  });

  testWidgets('the four cards carry four distinct accent colors', (
    tester,
  ) async {
    await pumpGrid(tester);

    final accents = <Color?>[
      tester.widget<Icon>(find.byIcon(Icons.trending_up)).color,
      tester.widget<Icon>(find.byIcon(Icons.receipt_long)).color,
      tester.widget<Icon>(find.byIcon(Icons.inventory_2)).color,
      tester.widget<Icon>(find.byIcon(Icons.people)).color,
    ];

    expect(accents.toSet().length, 4);
  });
}
