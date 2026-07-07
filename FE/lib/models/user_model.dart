import 'dart:convert';
import 'package:equatable/equatable.dart';

enum UserRole { customer, manager, admin }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final String? brandName;
  final String? brandLogoUrl;
  final String? address;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.customer,
    this.brandName,
    this.brandLogoUrl,
    this.address,
    required this.createdAt,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.customer:
        return 'Khách hàng';
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isCustomer => role == UserRole.customer;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role.name,
        'brand_name': brandName,
        'brand_logo_url': brandLogoUrl,
        'address': address,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] ?? '',
        email: map['email'] ?? '',
        fullName: map['full_name'] ?? '',
        phone: map['phone'],
        avatarUrl: map['avatar_url'],
        role: UserRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => UserRole.customer,
        ),
        brandName: map['brand_name'],
        brandLogoUrl: map['brand_logo_url'],
        address: map['address'] is Map ? jsonEncode(map['address']) : map['address'],
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? address,
    String? brandName,
    String? brandLogoUrl,
    UserRole? role,
  }) =>
      UserModel(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        brandName: brandName ?? this.brandName,
        brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
        address: address ?? this.address,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, email, fullName, phone, avatarUrl, role, brandName, brandLogoUrl, address, createdAt];
}
