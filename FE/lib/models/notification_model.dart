import 'dart:convert';
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? imageUrl;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  String? get orderId => data?['order_id'] as String?;
  String? get orderNumber => data?['order_number'] as String?;
  String? get orderStatus => data?['status'] as String?;

  bool get isOrderUpdate => type == 'order_update';
  bool get isNewOrder => type == 'new_order';

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'image_url': imageUrl,
        'type': type,
        'data': data,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        imageUrl: map['image_url'],
        type: map['type'],
        data: map['data'] is String
            ? json.decode(map['data'])
            : map['data'] as Map<String, dynamic>?,
        isRead: map['is_read'] ?? false,
        createdAt:
            DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        imageUrl: imageUrl,
        type: type,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, userId, title, body, imageUrl, type, data, isRead, createdAt];
}
