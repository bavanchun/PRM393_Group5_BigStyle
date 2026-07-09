import 'package:bigstyle_app/blocs/admin/admin_bloc.dart';
import 'package:bigstyle_app/blocs/admin/admin_event.dart';
import 'package:bigstyle_app/blocs/admin/admin_state.dart';
import 'package:bigstyle_app/models/user_model.dart';
import 'package:bigstyle_app/services/admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAdminService extends AdminService {
  FakeAdminService({this.addUserError, this.usersAfterAdd = const []})
    : super(
        functionInvoker: (_, {body}) async {
          throw UnimplementedError();
        },
      );

  final Object? addUserError;
  final List<UserModel> usersAfterAdd;
  Map<String, Object?>? addUserPayload;

  @override
  Future<void> addUser({
    required String email,
    required String fullName,
    required String role,
    String? brandName,
  }) async {
    addUserPayload = {
      'email': email,
      'fullName': fullName,
      'role': role,
      'brandName': brandName,
    };
    final error = addUserError;
    if (error != null) throw error;
  }

  @override
  Future<List<UserModel>> getAllUsers() async => usersAfterAdd;
}

void main() {
  group('AdminBloc AdminAddUser', () {
    test('emits loading then success and forwards brandName', () async {
      final createdUser = UserModel(
        id: 'manager-id',
        email: 'new.manager@example.com',
        fullName: 'New Manager',
        role: UserRole.manager,
        brandName: 'New Brand',
        createdAt: DateTime(2026),
      );
      final service = FakeAdminService(usersAfterAdd: [createdUser]);
      final bloc = AdminBloc(service);

      bloc.add(
        const AdminAddUser(
          email: 'new.manager@example.com',
          fullName: 'New Manager',
          role: 'manager',
          brandName: 'New Brand',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdminState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AdminState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.users, 'users', [createdUser])
              .having(
                (s) => s.successMessage,
                'successMessage',
                'Tạo người dùng thành công! Email invite đã được gửi.',
              ),
        ]),
      );
      expect(service.addUserPayload, {
        'email': 'new.manager@example.com',
        'fullName': 'New Manager',
        'role': 'manager',
        'brandName': 'New Brand',
      });

      await bloc.close();
    });

    test('emits loading then error when service fails', () async {
      final service = FakeAdminService(
        addUserError: Exception('admin required'),
      );
      final bloc = AdminBloc(service);

      bloc.add(
        const AdminAddUser(
          email: 'new.manager@example.com',
          fullName: 'New Manager',
          role: 'manager',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdminState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AdminState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.error, 'error', contains('admin required')),
        ]),
      );

      await bloc.close();
    });
  });
}
