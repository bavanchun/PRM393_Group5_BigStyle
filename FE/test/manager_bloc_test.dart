import 'dart:async';

import 'package:bigstyle_app/blocs/manager/manager_bloc.dart';
import 'package:bigstyle_app/blocs/manager/manager_event.dart';
import 'package:bigstyle_app/models/order_model.dart';
import 'package:bigstyle_app/models/order_status.dart';
import 'package:bigstyle_app/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'latest manager order filter wins when requests finish out of order',
    () async {
      final service = _DelayedOrderService();
      final bloc = ManagerBloc(service);
      addTearDown(bloc.close);

      final pendingLoading = bloc.stream.firstWhere(
        (state) => state.isOrdersLoading && state.selectedStatus == 'pending',
      );
      bloc.add(const ManagerLoadOrders(status: 'pending'));
      await pendingLoading;

      final deliveredLoading = bloc.stream.firstWhere(
        (state) => state.isOrdersLoading && state.selectedStatus == 'delivered',
      );
      bloc.add(const ManagerLoadOrders(status: 'delivered'));
      await deliveredLoading;

      final deliveredLoaded = bloc.stream.firstWhere(
        (state) => !state.isOrdersLoading && state.orders.isNotEmpty,
      );
      service.complete('delivered');
      await deliveredLoaded;
      service.complete('pending');
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.selectedStatus, 'delivered');
      expect(bloc.state.orders.single.status, OrderStatus.delivered);
    },
  );
}

class _DelayedOrderService extends OrderService {
  final _requests = <String, Completer<List<OrderModel>>>{};

  _DelayedOrderService()
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-publishable-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  Future<List<OrderModel>> getAllOrders({String? status}) {
    final completer = Completer<List<OrderModel>>();
    _requests[status!] = completer;
    return completer.future;
  }

  void complete(String status) {
    _requests[status]!.complete([
      OrderModel(
        id: '$status-order',
        userId: 'user-1',
        items: const [],
        subtotal: 100000,
        total: 100000,
        status: OrderStatus.values.byName(status),
        createdAt: DateTime(2026, 6, 20),
      ),
    ]);
  }
}
