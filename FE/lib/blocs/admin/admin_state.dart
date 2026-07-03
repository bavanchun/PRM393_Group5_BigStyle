import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  // Dashboard
  final Map<String, dynamic> dashboardStats;

  // Users
  final List<UserModel> users;

  // Categories
  final List<Map<String, dynamic>> categories;

  const AdminState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.dashboardStats = const {},
    this.users = const [],
    this.categories = const [],
  });

  AdminState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Map<String, dynamic>? dashboardStats,
    List<UserModel>? users,
    List<Map<String, dynamic>>? categories,
  }) =>
      AdminState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
        dashboardStats: dashboardStats ?? this.dashboardStats,
        users: users ?? this.users,
        categories: categories ?? this.categories,
      );

  @override
  List<Object?> get props => [
        isLoading,
        error,
        successMessage,
        dashboardStats,
        users,
        categories,
      ];
}
