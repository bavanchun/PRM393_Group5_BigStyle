import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../utils/currency_format.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/manager_product/manager_product_bloc.dart';
import '../../../blocs/manager_product/manager_product_event.dart';
import '../../../blocs/manager_product/manager_product_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/product_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/app_error_state.dart';
import 'manager_create_product_screen.dart';
import 'manager_product_detail_screen.dart';

class ManagerProductListScreen extends StatefulWidget {
  const ManagerProductListScreen({super.key});

  @override
  State<ManagerProductListScreen> createState() =>
      _ManagerProductListScreenState();
}

class _ManagerProductListScreenState extends State<ManagerProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  // Last successfully loaded list. The bloc auto-dispatches a reload after
  // every create/update/delete (see ManagerProductBloc); without this cache
  // a transient failure of that background reload would destroy an
  // already-successfully-shown list and replace it with a full-screen error
  // right after the user's own edit succeeded. Mirrors
  // manager_category_list_screen.dart's _categories pattern.
  List<ProductModel>? _lastLoadedProducts;

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

  String _roleBadgeLabel(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị';
      case UserRole.manager:
        return 'Quản lý';
      default:
        return 'Nhân viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 2,
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            final title = user?.fullName.isNotEmpty == true
                ? user!.fullName
                : 'BigStyle';
            return Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.headlineLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _roleBadgeLabel(user?.role),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocConsumer<ManagerProductBloc, ManagerProductState>(
        listener: (context, state) {
          if (state is ManagerProductLoaded) {
            setState(() => _lastLoadedProducts = state.products);
          } else if (state is ManagerProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primary,
              ),
            );
          } else if (state is ManagerProductError &&
              _lastLoadedProducts != null) {
            // Background refresh failed but a list is already on screen —
            // toast only; the builder keeps rendering the cached products
            // (see _lastLoadedProducts) instead of the full AppErrorState.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
          // ManagerProductError with no prior cache: no SnackBar here — the
          // builder renders the full AppErrorState instead, and a SnackBar
          // on top of that would double up the same message.
        },
        builder: (context, state) {
          List<ProductModel> products = _lastLoadedProducts ?? [];
          bool isLoading =
              _lastLoadedProducts == null &&
              (state is ManagerProductLoading ||
                  state is ManagerProductOperationSuccess);
          String? errorMessage;

          if (state is ManagerProductLoaded) {
            products = state.products;
          } else if (state is ManagerProductError &&
              _lastLoadedProducts == null) {
            errorMessage = state.error;
          }

          if (_searchQuery.isNotEmpty) {
            products = products
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
                )
                .toList();
          }
          if (_selectedStatus != 'all') {
            bool isActiveFilter = _selectedStatus == 'active';
            products = products
                .where((p) => p.isActive == isActiveFilter)
                .toList();
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
                          Text(
                            'Danh mục sản phẩm',
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quản lý kho hàng, giá bán và trạng thái hiển thị.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tổng: ${products.length}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildFilterBar(),

              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : (errorMessage != null && products.isEmpty)
                    ? AppErrorState(
                        message: errorMessage,
                        onRetry: () => context.read<ManagerProductBloc>().add(
                          LoadManagerProductsEvent(),
                        ),
                      )
                    : _buildAdminProductList(products),
              ),

              _buildFooter(products.length),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manager-products-fab',
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
        icon: const Icon(Icons.add, color: AppColors.onPrimary),
        label: Text(
          'THÊM SẢN PHẨM MỚI',
          style: AppTypography.button.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: AppColors.primary,
              ),
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
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    labelStyle: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'all',
                      child: Text(
                        'Tất cả trạng thái',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'active',
                      child: Text(
                        'Đang bán',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'hidden',
                      child: Text(
                        'Tạm ẩn',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
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
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm nào.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 80,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isHidden = !product.isActive;

          int totalStock = product.variants.fold(
            0,
            (sum, v) => sum + v.stockQty,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isHidden ? AppColors.divider : AppColors.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isHidden
                    ? AppColors.border
                    : AppColors.border.withValues(alpha: 0.3),
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
                              ? const ColorFilter.mode(
                                  AppColors.grayscaleFilter,
                                  BlendMode.saturation,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
                          child: product.images.isNotEmpty
                              ? Image.network(
                                  product.images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.divider,
                                      child: const Icon(
                                        Icons.image,
                                        color: AppColors.onPrimary,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: AppColors.divider,
                                  child: const Icon(
                                    Icons.image,
                                    color: AppColors.onPrimary,
                                  ),
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
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isHidden
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: isHidden
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatVnd(product.price),
                            style: AppTypography.priceSmall.copyWith(
                              fontSize: 13,
                              color: isHidden
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isHidden
                                      ? AppColors.divider
                                      : AppColors.success.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isHidden
                                          ? Icons.visibility_off
                                          : Icons.check_circle,
                                      size: 10,
                                      color: isHidden
                                          ? AppColors.textSecondary
                                          : AppColors.success,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isHidden ? 'Tạm ẩn' : 'Đang bán',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: isHidden
                                            ? AppColors.textSecondary
                                            : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Tồn kho: $totalStock',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(product.createdAt)}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppColors.textHint),
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
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Text(
        'Hiển thị $count trên $count sản phẩm',
        style: AppTypography.caption.copyWith(fontSize: 11),
      ),
    );
  }
}
