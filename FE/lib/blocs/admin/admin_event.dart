import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

// Dashboard
class AdminLoadDashboard extends AdminEvent {
  const AdminLoadDashboard();
}

// Users
class AdminLoadUsers extends AdminEvent {
  const AdminLoadUsers();
}

class AdminUpdateUserRole extends AdminEvent {
  final String userId;
  final UserRole newRole;
  const AdminUpdateUserRole(this.userId, this.newRole);
  @override
  List<Object?> get props => [userId, newRole];
}

class AdminUpdateBrandName extends AdminEvent {
  final String userId;
  final String brandName;
  const AdminUpdateBrandName(this.userId, this.brandName);
  @override
  List<Object?> get props => [userId, brandName];
}

class AdminAddUser extends AdminEvent {
  final String email;
  final String fullName;
  final String role;
  final String? brandName;
  const AdminAddUser({
    required this.email,
    required this.fullName,
    required this.role,
    this.brandName,
  });
  @override
  List<Object?> get props => [email, fullName, role, brandName];
}

// Categories
class AdminLoadCategories extends AdminEvent {
  const AdminLoadCategories();
}

class AdminCreateCategory extends AdminEvent {
  final String name;
  final String slug;
  final String? imageUrl;
  final int sortOrder;
  const AdminCreateCategory({
    required this.name,
    required this.slug,
    this.imageUrl,
    this.sortOrder = 0,
  });
  @override
  List<Object?> get props => [name, slug, imageUrl, sortOrder];
}

class AdminUpdateCategory extends AdminEvent {
  final String id;
  final Map<String, dynamic> updates;
  const AdminUpdateCategory(this.id, this.updates);
  @override
  List<Object?> get props => [id, updates];
}

class AdminDeleteCategory extends AdminEvent {
  final String id;
  const AdminDeleteCategory(this.id);
  @override
  List<Object?> get props => [id];
}
