import 'package:equatable/equatable.dart';

class ShippingRateModel extends Equatable {
  final String id;
  final String fromProvince;
  final String toProvince;
  final double baseFee;
  final double freeThreshold;
  final bool isActive;

  const ShippingRateModel({
    required this.id,
    required this.fromProvince,
    required this.toProvince,
    required this.baseFee,
    this.freeThreshold = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'from_province': fromProvince,
        'to_province': toProvince,
        'base_fee': baseFee,
        'free_threshold': freeThreshold,
        'is_active': isActive,
      };

  factory ShippingRateModel.fromMap(Map<String, dynamic> map) =>
      ShippingRateModel(
        id: map['id'] ?? '',
        fromProvince: map['from_province'] ?? '',
        toProvince: map['to_province'] ?? '',
        baseFee: (map['base_fee'] as num?)?.toDouble() ?? 30000,
        freeThreshold:
            (map['free_threshold'] as num?)?.toDouble() ?? 0,
        isActive: map['is_active'] ?? true,
      );

  @override
  List<Object?> get props =>
      [id, fromProvince, toProvince, baseFee, freeThreshold, isActive];
}
