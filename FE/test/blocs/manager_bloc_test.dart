import 'dart:async';

import 'package:bigstyle_app/blocs/manager/manager_bloc.dart';
import 'package:bigstyle_app/blocs/manager/manager_event.dart';
import 'package:bigstyle_app/blocs/manager/manager_state.dart';
import 'package:bigstyle_app/models/manager_dashboard_stats.dart';
import 'package:bigstyle_app/models/order_model.dart';
import 'package:bigstyle_app/models/order_status.dart';
import 'package:bigstyle_app/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake mirrors FakeAdminService (test/blocs/admin_bloc_test.dart) but
/// OrderService's constructor falls back to Supabase.instance.client when
/// no client is given, so a dummy SupabaseClient must be passed to super —
/// none of its methods are ever invoked because every method below is
/// overridden.
class FakeOrderService extends OrderService {
  FakeOrderService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  List<OrderModel> ordersResult = const [];
  Object? updateStatusError;

  ManagerDashboardStats defaultStats = const ManagerDashboardStats(
    todayRevenue: 0,
    pendingOrderCount: 0,
    productCount: 0,
    customerCount: 0,
  );
  final List<Future<ManagerDashboardStats> Function()> statsResponses = [];

  int getAllOrdersCallCount = 0;
  int getDashboardStatsCallCount = 0;
  int updateOrderStatusCallCount = 0;

  @override
  Future<List<OrderModel>> getAllOrders({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    getAllOrdersCallCount++;
    return ordersResult;
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? reason,
  }) async {
    updateOrderStatusCallCount++;
    final error = updateStatusError;
    if (error != null) throw error;
  }

  @override
  Future<ManagerDashboardStats> getDashboardStats() async {
    getDashboardStatsCallCount++;
    if (statsResponses.isNotEmpty) {
      final next = statsResponses.removeAt(0);
      return next();
    }
    return defaultStats;
  }
}

OrderModel _order({
  required String id,
  OrderStatus status = OrderStatus.pending,
}) {
  return OrderModel(
    id: id,
    userId: 'user-1',
    customerName: 'Trần Thị Demo',
    items: const [],
    subtotal: 100000,
    total: 100000,
    status: status,
    createdAt: DateTime(2026, 7, 10),
  );
}

const _statsWithOnePending = ManagerDashboardStats(
  todayRevenue: 0,
  pendingOrderCount: 1,
  productCount: 1,
  customerCount: 1,
);

void main() {
  group('ManagerBloc ManagerUpdateOrderStatus', () {
    test(
      'patches recentOrders entry and refreshes dashboardStats on success',
      () async {
        final service = FakeOrderService()
          ..ordersResult = [_order(id: 'order-1')]
          ..statsResponses.add(() async => _statsWithOnePending)
          ..statsResponses.add(
            () async => const ManagerDashboardStats(
              todayRevenue: 0,
              pendingOrderCount: 0,
              productCount: 1,
              customerCount: 1,
            ),
          );
        final bloc = ManagerBloc(service);

        bloc.add(const ManagerLoadDashboard());
        await bloc.stream.firstWhere((s) => !s.isDashboardLoading);
        expect(bloc.state.recentOrders.single.status, OrderStatus.pending);

        bloc.add(
          const ManagerUpdateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ManagerState>()
                .having((s) => s.isUpdatingStatus, 'isUpdatingStatus', false)
                .having(
                  (s) => s.recentOrders.single.status,
                  'recentOrders[0].status',
                  OrderStatus.confirmed,
                )
                .having(
                  (s) => s.dashboardStats?.pendingOrderCount,
                  'dashboardStats.pendingOrderCount',
                  0,
                )
                .having(
                  (s) => s.isDashboardLoading,
                  'isDashboardLoading',
                  false,
                ),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'update failure sets error and leaves recentOrders/stats untouched',
      () async {
        final service = FakeOrderService()
          ..ordersResult = [_order(id: 'order-1')]
          ..statsResponses.add(() async => _statsWithOnePending);
        final bloc = ManagerBloc(service);

        bloc.add(const ManagerLoadDashboard());
        await bloc.stream.firstWhere((s) => !s.isDashboardLoading);
        final seededStats = bloc.state.dashboardStats;

        service.updateStatusError = Exception('network down');
        bloc.add(
          const ManagerUpdateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ManagerState>()
                .having((s) => s.isUpdatingStatus, 'isUpdatingStatus', false)
                .having(
                  (s) => s.error,
                  'error',
                  'Cập nhật trạng thái đơn hàng thất bại',
                )
                .having(
                  (s) => s.recentOrders.single.status,
                  'recentOrders[0].status',
                  OrderStatus.pending,
                )
                .having((s) => s.dashboardStats, 'dashboardStats', seededStats),
          ),
        );
        // Refresh must never be attempted after a failed update.
        expect(service.getDashboardStatsCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'stats-refresh failure after a successful update is soft: no false '
      '"update failed" error, order patch kept, stats unchanged',
      () async {
        final service = FakeOrderService()
          ..ordersResult = [_order(id: 'order-1')]
          ..statsResponses.add(() async => _statsWithOnePending);
        final bloc = ManagerBloc(service);

        bloc.add(const ManagerLoadDashboard());
        await bloc.stream.firstWhere((s) => !s.isDashboardLoading);
        final seededStats = bloc.state.dashboardStats;

        service.statsResponses.add(() async => throw Exception('stats down'));
        bloc.add(
          const ManagerUpdateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ManagerState>()
                .having((s) => s.isUpdatingStatus, 'isUpdatingStatus', false)
                .having((s) => s.error, 'error', isNull)
                .having(
                  (s) => s.recentOrders.single.status,
                  'recentOrders[0].status',
                  OrderStatus.confirmed,
                )
                .having((s) => s.dashboardStats, 'dashboardStats', seededStats)
                .having(
                  (s) => s.isDashboardLoading,
                  'isDashboardLoading',
                  false,
                ),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'interleaving: a slower ManagerLoadDashboard does not clobber the '
      'fresher stats written by ManagerUpdateOrderStatus, and loading is '
      'never left stuck',
      () async {
        final slowStatsCompleter = Completer<ManagerDashboardStats>();
        const freshStats = ManagerDashboardStats(
          todayRevenue: 0,
          pendingOrderCount: 0,
          productCount: 1,
          customerCount: 1,
        );
        const staleStats = ManagerDashboardStats(
          todayRevenue: 0,
          pendingOrderCount: 99,
          productCount: 99,
          customerCount: 99,
        );

        final service = FakeOrderService()
          ..ordersResult = [_order(id: 'order-1')]
          ..statsResponses.add(() => slowStatsCompleter.future)
          ..statsResponses.add(() async => freshStats);
        final bloc = ManagerBloc(service);

        bloc.add(const ManagerLoadDashboard());
        bloc.add(
          const ManagerUpdateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
          ),
        );

        // Let the fast update-handler path (2nd stats response) land while
        // the dashboard load's stats call is still parked on the completer.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.isDashboardLoading, isFalse);
        expect(bloc.state.dashboardStats, freshStats);

        // Now resolve the slow (stale) dashboard-load stats call — it must
        // be rejected by the request-id guard, not overwrite freshStats.
        slowStatsCompleter.complete(staleStats);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.dashboardStats, freshStats);
        expect(bloc.state.isDashboardLoading, isFalse);

        await bloc.close();
      },
    );
  });
}
