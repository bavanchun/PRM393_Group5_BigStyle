import 'package:bigstyle_app/blocs/product/product_bloc.dart';
import 'package:bigstyle_app/blocs/product/product_event.dart';
import 'package:bigstyle_app/models/category_model.dart';
import 'package:bigstyle_app/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeProductService extends ProductService {
  FakeProductService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  List<CategoryModel> categories = const [];
  Object? categoriesError;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final error = categoriesError;
    if (error != null) throw error;
    return categories;
  }
}

void main() {
  late FakeProductService service;

  setUp(() => service = FakeProductService());

  test('categories failure raises an explicit flag instead of silent swallow',
      () async {
    service.categoriesError = Exception('boom');
    final bloc = ProductBloc(service);

    bloc.add(const ProductLoadCategories());
    final state = await bloc.stream.firstWhere((s) => s.categoriesFailed);

    expect(state.categoriesFailed, isTrue);
    expect(state.categories, isEmpty);
    await bloc.close();
  });

  test('categories success clears the failure flag', () async {
    service.categories = const [
      CategoryModel(id: 'c1', name: 'Áo', slug: 'ao'),
    ];
    final bloc = ProductBloc(service);

    bloc.add(const ProductLoadCategories());
    final state = await bloc.stream.firstWhere((s) => s.categories.isNotEmpty);

    expect(state.categoriesFailed, isFalse);
    await bloc.close();
  });
}
