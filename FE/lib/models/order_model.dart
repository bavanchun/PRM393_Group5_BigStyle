import 'package:equatable/equatable.dart';
import 'order_status.dart';
import 'product_model.dart';

class OrderItem extends Equatable {
  final String productId;
  final ProductModel? product;
  final String size;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productId,
    this.product,
    required this.size,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'size': size,
        'quantity': quantity,
        'price': price,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['product_id'] ?? '',
        product: map['product'] != null
            ? ProductModel.fromMap(map['product'])
            : null,
        size: map['size'] ?? '',
        quantity: map['quantity'] ?? 1,
        price: (map['price'] ?? 0).toDouble(),
      );

  @override
  List<Object?> get props => [productId, product, size, quantity, price];
}

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final OrderStatus status;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.shippingFee = 0,
    required this.total,
    this.status = OrderStatus.pending,
    this.address,
    this.latitude,
    this.longitude,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'shipping_fee': shippingFee,
        'total': total,
        'status': status.name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        items: (map['items'] as List?)
                ?.map((e) => OrderItem.fromMap(e))
                .toList() ??
            [],
        subtotal: (map['subtotal'] ?? 0).toDouble(),
        shippingFee: (map['shipping_fee'] ?? 0).toDouble(),
        total: (map['total'] ?? 0).toDouble(),
        status: OrderStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => OrderStatus.pending,
        ),
        address: map['address'],
        latitude: map['latitude']?.toDouble(),
        longitude: map['longitude']?.toDouble(),
        note: map['note'],
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? ''),
      );

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
        id: id,
        userId: userId,
        items: items,
        subtotal: subtotal,
        shippingFee: shippingFee,
        total: total,
        status: status ?? this.status,
        address: address,
        latitude: latitude,
        longitude: longitude,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        subtotal,
        shippingFee,
        total,
        status,
        address,
        latitude,
        longitude,
        note,
        createdAt,
        updatedAt,
      ];
}
