import 'package:bigstyle_app/services/admin_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AdminService.addUser', () {
    test('invokes admin-invite-user function with invite payload', () async {
      String? invokedFunction;
      Object? invokedBody;
      final service = AdminService(
        functionInvoker: (functionName, {body}) async {
          invokedFunction = functionName;
          invokedBody = body;
          return const FunctionResponse(status: 200, data: {'success': true});
        },
      );

      await service.addUser(
        email: 'new.manager@example.com',
        fullName: 'New Manager',
        role: 'manager',
        brandName: 'New Brand',
      );

      expect(invokedFunction, 'admin-invite-user');
      expect(invokedBody, {
        'email': 'new.manager@example.com',
        'fullName': 'New Manager',
        'role': 'manager',
        'brandName': 'New Brand',
      });
    });

    test('throws a readable error when function returns failure', () async {
      final service = AdminService(
        functionInvoker: (_, {body}) async => const FunctionResponse(
          status: 403,
          data: {'error': 'admin required'},
        ),
      );

      expect(
        () => service.addUser(
          email: 'new.manager@example.com',
          fullName: 'New Manager',
          role: 'manager',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('admin required'),
          ),
        ),
      );
    });
  });
}
