import 'dart:async';

import 'package:bigstyle_app/blocs/refund_request/refund_request_bloc.dart';
import 'package:bigstyle_app/blocs/refund_request/refund_request_event.dart';
import 'package:bigstyle_app/models/refund_request_model.dart';
import 'package:bigstyle_app/services/refund_request_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeRefundRequestService extends RefundRequestService {
  FakeRefundRequestService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  final Map<String, RefundRequestModel> requestsByOrder = {};
  Set<String> pendingOrderIds = const {};
  Object? submitError;
  Object? decideError;
  int decideCallCount = 0;

  // A gate keyed to one orderId, so a test can make that order's fetch hang
  // while a different order's fetch (no gate match) proceeds and resolves
  // first — reproducing an overlapping-load race.
  String? gatedOrderId;
  Completer<void>? getForOrderGate;
  // Delays every decide() call until released, regardless of orderId — used
  // to deterministically interleave a decide with a subsequent load.
  Completer<void>? decideGate;

  @override
  Future<RefundRequestModel?> getForOrder(String orderId) async {
    if (orderId == gatedOrderId && getForOrderGate != null) {
      await getForOrderGate!.future;
    }
    return requestsByOrder[orderId];
  }

  @override
  Future<Set<String>> getPendingOrderIds() async => pendingOrderIds;

  @override
  Future<void> submit({
    required String orderId,
    required String userId,
    required String reason,
  }) async {
    final error = submitError;
    if (error != null) throw error;
    requestsByOrder[orderId] = RefundRequestModel(
      id: 'r-$orderId',
      orderId: orderId,
      userId: userId,
      reason: reason,
      createdAt: DateTime(2026, 7, 13),
    );
  }

  @override
  Future<void> decide({
    required String requestId,
    required RefundRequestStatus decision,
    String? note,
  }) async {
    decideCallCount++;
    if (decideGate != null) await decideGate!.future;
    final error = decideError;
    if (error != null) throw error;
    final entry = requestsByOrder.entries.firstWhere(
      (e) => e.value.id == requestId,
    );
    requestsByOrder[entry.key] = RefundRequestModel(
      id: entry.value.id,
      orderId: entry.value.orderId,
      userId: entry.value.userId,
      reason: entry.value.reason,
      status: decision,
      managerNote: note,
      createdAt: entry.value.createdAt,
      decidedAt: DateTime(2026, 7, 13),
    );
  }
}

RefundRequestModel _pending(String orderId) => RefundRequestModel(
  id: 'r-$orderId',
  orderId: orderId,
  userId: 'u1',
  reason: 'Sản phẩm bị lỗi',
  createdAt: DateTime(2026, 7, 13),
);

void main() {
  late FakeRefundRequestService service;
  late RefundRequestBloc bloc;

  setUp(() {
    service = FakeRefundRequestService();
    bloc = RefundRequestBloc(service);
  });

  tearDown(() => bloc.close());

  group('RefundRequestLoadForOrder', () {
    test('loads an existing request', () async {
      service.requestsByOrder['o1'] = _pending('o1');
      bloc.add(const RefundRequestLoadForOrder('o1'));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(state.currentRequest?.orderId, 'o1');
    });

    test('clears currentRequest when none exists for the order', () async {
      // Seed a request for a DIFFERENT order, then load one with none.
      service.requestsByOrder['o1'] = _pending('o1');
      bloc.add(const RefundRequestLoadForOrder('o1'));
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const RefundRequestLoadForOrder('o2'));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(state.currentRequest, isNull);
    });
  });

  group('RefundRequestSubmit', () {
    test('success reloads and exposes the created request', () async {
      // The real screen always dispatches LoadForOrder before the submit
      // button can even be visible — this establishes _requestedOrderId the
      // same way, rather than testing an unrealistic bare-Submit call.
      bloc.add(const RefundRequestLoadForOrder('o1'));
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(
        const RefundRequestSubmit(
          orderId: 'o1',
          userId: 'u1',
          reason: 'Không vừa size',
        ),
      );
      final state = await bloc.stream.firstWhere((s) => !s.isProcessing);
      expect(state.currentRequest?.reason, 'Không vừa size');
      expect(state.error, isNull);
    });

    test(
      'server-side rejection (not eligible) surfaces a friendly error',
      () async {
        service.submitError = Exception(
          'new row violates row-level security policy',
        );
        bloc.add(
          const RefundRequestSubmit(orderId: 'o1', userId: 'u1', reason: 'x'),
        );
        final state = await bloc.stream.firstWhere((s) => s.error != null);
        expect(state.error, isNotNull);
        expect(state.currentRequest, isNull);
      },
    );
  });

  group('RefundRequestDecide', () {
    test(
      'approve updates currentRequest and drops the order from pendingOrderIds',
      () async {
        service.requestsByOrder['o1'] = _pending('o1');
        service.pendingOrderIds = {'o1', 'o2'};
        bloc.add(const RefundRequestLoadForOrder('o1'));
        await bloc.stream.firstWhere((s) => !s.isLoading);
        bloc.add(const RefundRequestLoadPendingOrderIds());
        await bloc.stream.firstWhere((s) => s.pendingOrderIds.contains('o1'));

        bloc.add(
          const RefundRequestDecide(
            requestId: 'r-o1',
            orderId: 'o1',
            decision: RefundRequestStatus.approved,
          ),
        );
        final state = await bloc.stream.firstWhere((s) => !s.isProcessing);

        expect(state.currentRequest?.status, RefundRequestStatus.approved);
        expect(state.pendingOrderIds, {'o2'});
      },
    );

    test('reject carries the manager note through to currentRequest', () async {
      service.requestsByOrder['o1'] = _pending('o1');
      bloc.add(const RefundRequestLoadForOrder('o1'));
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(
        const RefundRequestDecide(
          requestId: 'r-o1',
          orderId: 'o1',
          decision: RefundRequestStatus.rejected,
          note: 'Ngoài chính sách đổi trả',
        ),
      );
      final state = await bloc.stream.firstWhere((s) => !s.isProcessing);

      expect(state.currentRequest?.status, RefundRequestStatus.rejected);
      expect(state.currentRequest?.managerNote, 'Ngoài chính sách đổi trả');
    });

    test(
      'failure (e.g. non-manager or already-decided) emits an error, request unchanged',
      () async {
        service.requestsByOrder['o1'] = _pending('o1');
        bloc.add(const RefundRequestLoadForOrder('o1'));
        await bloc.stream.firstWhere((s) => !s.isLoading);

        service.decideError = Exception(
          'only managers can decide refund requests',
        );
        bloc.add(
          const RefundRequestDecide(
            requestId: 'r-o1',
            orderId: 'o1',
            decision: RefundRequestStatus.approved,
          ),
        );
        final state = await bloc.stream.firstWhere((s) => s.error != null);

        expect(state.error, isNotNull);
        expect(state.currentRequest?.status, RefundRequestStatus.pending);
      },
    );
  });

  group('RefundRequestLoadPendingOrderIds', () {
    test('populates pendingOrderIds', () async {
      service.pendingOrderIds = {'o1', 'o3'};
      bloc.add(const RefundRequestLoadPendingOrderIds());
      final state = await bloc.stream.firstWhere(
        (s) => s.pendingOrderIds.isNotEmpty,
      );
      expect(state.pendingOrderIds, {'o1', 'o3'});
    });
  });

  group('Concurrent overlap (interleaved dispatch, not just sequential)', () {
    test('a superseded order\'s late-resolving load does not overwrite the '
        'current order\'s state', () async {
      service.gatedOrderId = 'o1';
      service.getForOrderGate = Completer<void>();
      service.requestsByOrder['o1'] = _pending('o1');
      service.requestsByOrder['o2'] = _pending('o2');

      // o1's load starts and hangs mid-fetch (simulates a slow screen the
      // user has since navigated away from).
      bloc.add(const RefundRequestLoadForOrder('o1'));
      await Future<void>.delayed(Duration.zero);

      // The user opens order o2's detail screen before o1's fetch resolves.
      bloc.add(const RefundRequestLoadForOrder('o2'));
      final afterO2 = await bloc.stream.firstWhere(
        (s) => !s.isLoading && s.currentRequest?.orderId == 'o2',
      );
      expect(afterO2.currentRequest?.orderId, 'o2');

      // Now let o1's stale fetch finally resolve — it must be dropped, not
      // clobber o2's already-current state.
      service.getForOrderGate!.complete();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.currentRequest?.orderId, 'o2');
    });

    test(
      'a decide dispatched for a since-superseded order does not '
      'overwrite the current order\'s state, and still resets isProcessing',
      () async {
        service.requestsByOrder['o1'] = _pending('o1');
        service.requestsByOrder['o2'] = _pending('o2');
        bloc.add(const RefundRequestLoadForOrder('o1'));
        await bloc.stream.firstWhere((s) => !s.isLoading);

        // Decide fires for o1 (e.g. the manager tapped Approve just before
        // navigating away) and hangs mid-call...
        service.decideGate = Completer<void>();
        bloc.add(
          const RefundRequestDecide(
            requestId: 'r-o1',
            orderId: 'o1',
            decision: RefundRequestStatus.approved,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // ...then, before it resolves, the manager opens order o2's detail
        // screen (a real navigation, not gated — resolves immediately).
        bloc.add(const RefundRequestLoadForOrder('o2'));
        final afterO2 = await bloc.stream.firstWhere(
          (s) => !s.isLoading && s.currentRequest?.orderId == 'o2',
        );
        expect(afterO2.currentRequest?.orderId, 'o2');

        // Now let o1's decide finally resolve — it must reset isProcessing
        // (so the UI isn't stuck) without clobbering o2's already-current state.
        service.decideGate!.complete();
        final finalState = await bloc.stream.firstWhere((s) => !s.isProcessing);
        expect(finalState.currentRequest?.orderId, 'o2');
        expect(finalState.isProcessing, isFalse);
      },
    );
  });
}
