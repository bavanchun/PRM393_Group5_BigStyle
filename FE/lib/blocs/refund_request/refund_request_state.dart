import 'package:equatable/equatable.dart';
import '../../models/refund_request_model.dart';

class RefundRequestState extends Equatable {
  final bool isLoading;
  // Covers both submit (customer) and decide (manager) — a given screen only
  // ever does one of the two, so one flag is enough.
  final bool isProcessing;
  final RefundRequestModel? currentRequest;
  final Set<String> pendingOrderIds;
  final String? error;

  const RefundRequestState({
    this.isLoading = false,
    this.isProcessing = false,
    this.currentRequest,
    this.pendingOrderIds = const {},
    this.error,
  });

  RefundRequestState copyWith({
    bool? isLoading,
    bool? isProcessing,
    RefundRequestModel? currentRequest,
    bool clearCurrentRequest = false,
    Set<String>? pendingOrderIds,
    String? error,
  }) => RefundRequestState(
    isLoading: isLoading ?? this.isLoading,
    isProcessing: isProcessing ?? this.isProcessing,
    currentRequest: clearCurrentRequest
        ? null
        : (currentRequest ?? this.currentRequest),
    pendingOrderIds: pendingOrderIds ?? this.pendingOrderIds,
    error: error,
  );

  @override
  List<Object?> get props => [
    isLoading,
    isProcessing,
    currentRequest,
    pendingOrderIds,
    error,
  ];
}
