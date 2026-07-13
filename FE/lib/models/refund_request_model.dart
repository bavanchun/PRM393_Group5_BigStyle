import 'package:equatable/equatable.dart';

enum RefundRequestStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case RefundRequestStatus.pending:
        return 'Đang chờ xử lý';
      case RefundRequestStatus.approved:
        return 'Đã chấp nhận';
      case RefundRequestStatus.rejected:
        return 'Đã từ chối';
    }
  }
}

class RefundRequestModel extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final String reason;
  final RefundRequestStatus status;
  final String? managerNote;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const RefundRequestModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.reason,
    this.status = RefundRequestStatus.pending,
    this.managerNote,
    required this.createdAt,
    this.decidedAt,
  });

  factory RefundRequestModel.fromMap(Map<String, dynamic> map) {
    return RefundRequestModel(
      id: map['id'] ?? '',
      orderId: map['order_id'] ?? '',
      userId: map['user_id'] ?? '',
      reason: map['reason'] ?? '',
      status: RefundRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RefundRequestStatus.pending,
      ),
      managerNote: map['manager_note'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      decidedAt: map['decided_at'] != null
          ? DateTime.tryParse(map['decided_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    userId,
    reason,
    status,
    managerNote,
    createdAt,
    decidedAt,
  ];
}
