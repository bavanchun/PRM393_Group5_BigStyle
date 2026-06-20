import 'package:bigstyle_app/blocs/manager/manager_bloc.dart';
import 'package:bigstyle_app/models/manager_dashboard_stats.dart';
import 'package:bigstyle_app/models/order_model.dart';
import 'package:bigstyle_app/models/order_status.dart';
import 'package:bigstyle_app/screens/manager/manager_dashboard.dart';
import 'package:bigstyle_app/screens/manager/manager_orders_screen.dart';
import 'package:bigstyle_app/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('manager dashboard renders real service values', (tester) async {
    final service = _FakeOrderService();
    final bloc = ManagerBloc(service);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: ManagerDashboard()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đơn chờ xác nhận'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Khách hàng thật'), findsOneWidget);
    expect(find.text('12.5tr'), findsNothing);
  });

  testWidgets('manager orders filters and opens real order rows', (
    tester,
  ) async {
    final service = _FakeOrderService();
    final bloc = ManagerBloc(service);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: ManagerOrdersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khách hàng thật'), findsOneWidget);
    expect(find.text('Chi tiết'), findsOneWidget);

    await tester.tap(find.text('Đang xử lý'));
    await tester.pumpAndSettle();
    expect(service.lastStatus, 'processing');
  });
}

class _FakeOrderService extends OrderService {
  String? lastStatus;

  _FakeOrderService()
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-publishable-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  Future<ManagerDashboardStats> getDashboardStats() async {
    return const ManagerDashboardStats(
      todayRevenue: 250000,
      pendingOrderCount: 2,
      productCount: 15,
      customerCount: 7,
    );
  }

  @override
  Future<List<OrderModel>> getAllOrders({String? status}) async {
    lastStatus = status;
    return [_order(status: status)];
  }

  OrderModel _order({String? status}) {
    return OrderModel(
      id: '12345678-order',
      userId: 'user-1',
      customerName: 'Khách hàng thật',
      items: const [],
      subtotal: 250000,
      total: 250000,
      status: OrderStatus.values.firstWhere(
        (value) => value.name == status,
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime(2026, 6, 20),
    );
  }
}
