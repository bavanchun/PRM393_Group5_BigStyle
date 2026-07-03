import 'package:equatable/equatable.dart';

/// A promo code. `type` is 'percentage' (value = percent, optional maxDiscount
/// cap) or 'fixed' (value = absolute VND off). Discount math is authoritative
/// on the server (`validate_voucher` / `create_order` RPCs); this model is for
/// display + manager CRUD only.
class VoucherModel extends Equatable {
  final String id;
  final String code;
  final String type; // 'percentage' | 'fixed'
  final double value;
  final double minOrderAmount;
  final double? maxDiscount;
  final DateTime? expiresAt;
  final bool isActive;

  const VoucherModel({
    this.id = '',
    required this.code,
    required this.type,
    required this.value,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.expiresAt,
    this.isActive = true,
  });

  bool get isPercentage => type == 'percentage';

  factory VoucherModel.fromMap(Map<String, dynamic> map) => VoucherModel(
        id: map['id'] ?? '',
        code: map['code'] ?? '',
        type: map['type'] ?? 'fixed',
        value: (map['value'] as num?)?.toDouble() ?? 0,
        minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0,
        maxDiscount: (map['max_discount'] as num?)?.toDouble(),
        expiresAt: map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'])
            : null,
        isActive: map['is_active'] ?? true,
      );

  /// Insert/update payload. Omits `id` (DB-generated) and read-only fields.
  Map<String, dynamic> toMap() => {
        'code': code,
        'type': type,
        'value': value,
        'min_order_amount': minOrderAmount,
        'max_discount': maxDiscount,
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': isActive,
      };

  VoucherModel copyWith({
    String? id,
    String? code,
    String? type,
    double? value,
    double? minOrderAmount,
    double? maxDiscount,
    DateTime? expiresAt,
    bool? isActive,
  }) =>
      VoucherModel(
        id: id ?? this.id,
        code: code ?? this.code,
        type: type ?? this.type,
        value: value ?? this.value,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        maxDiscount: maxDiscount ?? this.maxDiscount,
        expiresAt: expiresAt ?? this.expiresAt,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props =>
      [id, code, type, value, minOrderAmount, maxDiscount, expiresAt, isActive];
}
