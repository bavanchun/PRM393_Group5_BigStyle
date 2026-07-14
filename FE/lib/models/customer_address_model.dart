import 'package:equatable/equatable.dart';

class CustomerAddressModel extends Equatable {
  final String id;
  final String userId;
  final String label;
  final String fullName;
  final String? phone;
  final String address;
  final String province;
  final String? district;
  final String? ward;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  const CustomerAddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullName,
    this.phone,
    required this.address,
    required this.province,
    this.district,
    this.ward,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'province': province,
        'district': district,
        'ward': ward,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };

  factory CustomerAddressModel.fromMap(Map<String, dynamic> map) =>
      CustomerAddressModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        label: map['label'] ?? 'Nhà',
        fullName: map['full_name'] ?? '',
        phone: map['phone'],
        address: map['address'] ?? '',
        province: map['province'] ?? '',
        district: map['district'],
        ward: map['ward'],
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        isDefault: map['is_default'] ?? false,
        createdAt:
            DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );

  CustomerAddressModel copyWith({
    String? label,
    String? fullName,
    String? phone,
    String? address,
    String? province,
    String? district,
    String? ward,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      CustomerAddressModel(
        id: id,
        userId: userId,
        label: label ?? this.label,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        province: province ?? this.province,
        district: district ?? this.district,
        ward: ward ?? this.ward,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id, userId, label, fullName, phone, address,
        province, district, ward, latitude, longitude,
        isDefault, createdAt,
      ];
}
