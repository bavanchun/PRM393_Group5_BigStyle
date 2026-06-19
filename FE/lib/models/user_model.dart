import 'dart:convert';
import 'package:equatable/equatable.dart';

enum UserRole { customer, manager }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final String? address;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.customer,
    this.address,
    required this.createdAt,
  });

  String get roleLabel => role == UserRole.manager ? 'Quản lý' : 'Khách hàng';

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role.name,
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
        address: map['address'] is Map ? jsonEncode(map['address']) : map['address'],
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? address,
  }) =>
      UserModel(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role,
        address: address ?? this.address,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, email, fullName, phone, avatarUrl, role, address, createdAt];
}
