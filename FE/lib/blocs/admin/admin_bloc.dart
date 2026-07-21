import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_event.dart';
import 'admin_state.dart';
import '../../services/admin_service.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminService _adminService;

  AdminBloc(this._adminService) : super(const AdminState()) {
    on<AdminLoadDashboard>(_onLoadDashboard);
    on<AdminLoadUsers>(_onLoadUsers);
    on<AdminUpdateUserRole>(_onUpdateUserRole);
    on<AdminUpdateBrandName>(_onUpdateBrandName);
    on<AdminAddUser>(_onAddUser);
    on<AdminLoadCategories>(_onLoadCategories);
    on<AdminCreateCategory>(_onCreateCategory);
    on<AdminUpdateCategory>(_onUpdateCategory);
    on<AdminDeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadDashboard(
    AdminLoadDashboard event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final stats = await _adminService.getDashboardStats();
      emit(state.copyWith(isLoading: false, dashboardStats: stats));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Lỗi tải thống kê: $e'));
    }
  }

  Future<void> _onLoadUsers(
    AdminLoadUsers event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final users = await _adminService.getAllUsers();
      emit(state.copyWith(isLoading: false, users: users));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: 'Lỗi tải danh sách người dùng: $e'),
      );
    }
  }

  Future<void> _onUpdateUserRole(
    AdminUpdateUserRole event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminService.updateUserRole(event.userId, event.newRole);
      final users = await _adminService.getAllUsers();
      emit(
        state.copyWith(
          users: users,
          successMessage: 'Cập nhật role thành công',
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật role: $e'));
    }
  }

  Future<void> _onUpdateBrandName(
    AdminUpdateBrandName event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminService.updateBrandName(event.userId, event.brandName);
      final users = await _adminService.getAllUsers();
      emit(
        state.copyWith(
          users: users,
          successMessage: 'Cập nhật tên thương hiệu thành công',
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật thương hiệu: $e'));
    }
  }

  Future<void> _onAddUser(AdminAddUser event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _adminService.addUser(
        email: event.email,
        fullName: event.fullName,
        role: event.role,
        brandName: event.brandName,
      );
      final users = await _adminService.getAllUsers();
      emit(
        state.copyWith(
          isLoading: false,
          users: users,
          successMessage:
              'Tạo người dùng thành công! Email invite đã được gửi.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Lỗi tạo người dùng: $e'));
    }
  }

  Future<void> _onLoadCategories(
    AdminLoadCategories event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final categories = await _adminService.getAllCategories();
      emit(state.copyWith(isLoading: false, categories: categories));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Lỗi tải danh mục: $e'));
    }
  }

  Future<void> _onCreateCategory(
    AdminCreateCategory event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminService.createCategory(
        name: event.name,
        slug: event.slug,
        imageUrl: event.imageUrl,
        sortOrder: event.sortOrder,
      );
      final categories = await _adminService.getAllCategories();
      emit(
        state.copyWith(
          categories: categories,
          successMessage: 'Tạo danh mục thành công',
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi tạo danh mục: $e'));
    }
  }

  Future<void> _onUpdateCategory(
    AdminUpdateCategory event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminService.updateCategory(event.id, event.updates);
      final categories = await _adminService.getAllCategories();
      emit(
        state.copyWith(
          categories: categories,
          successMessage: 'Cập nhật danh mục thành công',
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật danh mục: $e'));
    }
  }

  Future<void> _onDeleteCategory(
    AdminDeleteCategory event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminService.deleteCategory(event.id);
      final categories = await _adminService.getAllCategories();
      emit(
        state.copyWith(
          categories: categories,
          successMessage: 'Xóa danh mục thành công',
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi xóa danh mục: $e'));
    }
  }
}
