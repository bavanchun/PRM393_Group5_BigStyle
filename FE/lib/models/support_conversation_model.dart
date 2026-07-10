import 'package:equatable/equatable.dart';

/// A support conversation row. Preview + unread counters are denormalized and
/// trigger-maintained so the staff inbox needs no per-conversation queries.
class SupportConversationModel extends Equatable {
  final String id;
  final String customerId;
  final String status;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final int unreadForStaff;
  final int unreadForCustomer;

  const SupportConversationModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadForStaff = 0,
    this.unreadForCustomer = 0,
  });

  factory SupportConversationModel.fromMap(Map<String, dynamic> map) {
    return SupportConversationModel(
      id: map['id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      lastMessageAt:
          DateTime.tryParse(map['last_message_at'] as String? ?? '')
              ?.toLocal() ??
          DateTime.now(),
      lastMessagePreview: map['last_message_preview'] as String?,
      unreadForStaff: (map['unread_for_staff'] as num?)?.toInt() ?? 0,
      unreadForCustomer: (map['unread_for_customer'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    status,
    lastMessageAt,
    lastMessagePreview,
    unreadForStaff,
    unreadForCustomer,
  ];
}
