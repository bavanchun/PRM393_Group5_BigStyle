import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../blocs/manager_product/manager_product_bloc.dart';
import '../../../blocs/manager_product/manager_product_event.dart';
import '../../../blocs/manager_product/manager_product_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../models/product_model.dart';
import 'manager_create_product_screen.dart';
import 'manager_product_detail_screen.dart';

class ManagerProductListScreen extends StatefulWidget {
  const ManagerProductListScreen({super.key});

  @override
  State<ManagerProductListScreen> createState() => _ManagerProductListScreenState();
}

class _ManagerProductListScreenState extends State<ManagerProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ManagerProductBloc>().add(LoadManagerProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 2,
        title: Row(
          children: [
            const Flexible(
              child: Text(
                'Quản trị BigStyle',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Quản trị',
                style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<ManagerProductBloc, ManagerProductState>(
        listener: (context, state) {
          if (state is ManagerProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.primary),
            );
          } else if (state is ManagerProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          List<ProductModel> products = [];
          bool isLoading = state is ManagerProductLoading;
          
          if (state is ManagerProductLoaded) {
            products = state.products;
          } else if (state is ManagerProductOperationSuccess) {
            isLoading = true; 
          }

          if (_searchQuery.isNotEmpty) {
            products = products.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }
          if (_selectedStatus != 'all') {
            bool isActiveFilter = _selectedStatus == 'active';
            products = products.where((p) => p.isActive == isActiveFilter).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danh mục sản phẩm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quản lý kho hàng, giá bán và trạng thái hiển thị.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tổng: ${products.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildFilterBar(),

              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildAdminProductList(products),
              ),

              _buildFooter(products.length),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final bloc = context.read<ManagerProductBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const ManagerCreateProductScreen(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('THÊM SẢN PHẨM MỚI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    labelStyle: TextStyle(fontSize: 11, color: AppColors.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'all',
                      child: Text('Tất cả trạng thái', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem<String>(
                      value: 'active',
                      child: Text('Đang bán', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem<String>(
                      value: 'hidden',
                      child: Text('Tạm ẩn', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm nào.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ManagerProductBloc>().add(LoadManagerProductsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isHidden = !product.isActive;
          
          int totalStock = product.variants.fold(0, (sum, v) => sum + v.stockQty);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isHidden ? const Color(0xFFF9F6F5) : Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isHidden ? Colors.grey.shade300 : AppColors.border.withOpacity(0.3),
              ),
            ),
            child: InkWell(
              onTap: () {
                final bloc = context.read<ManagerProductBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: ManagerProductDetailScreen(product: product),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: ColorFiltered(
                          colorFilter: isHidden
                              ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: Image.network(
                            product.images.isNotEmpty ? product.images.first : 'https://via.placeholder.com/150',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isHidden ? Colors.grey[700] : Colors.black,
                              decoration: isHidden ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPrice(product.price),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isHidden ? Colors.grey : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isHidden ? Colors.grey[300] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isHidden ? Icons.visibility_off : Icons.check_circle,
                                      size: 10,
                                      color: isHidden ? Colors.grey[700] : Colors.green[700],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isHidden ? 'Tạm ẩn' : 'Đang bán',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: isHidden ? Colors.grey[700] : Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Tồn kho: $totalStock',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Danh mục: ${product.category?.name ?? "Chưa phân loại"}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(product.createdAt)}',
                                style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Text(
        'Hiển thị $count trên $count sản phẩm',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }
}
