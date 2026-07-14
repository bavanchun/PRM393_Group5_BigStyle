import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../utils/currency_format.dart';
import '../../../blocs/manager_product/manager_product_bloc.dart';
import '../../../blocs/manager_product/manager_product_event.dart';
import '../../../blocs/manager_product/manager_product_state.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/notification/notification_bloc.dart';
import '../../../blocs/notification/notification_event.dart';
import '../../../blocs/notification/notification_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../models/product_model.dart';
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

  // Draggable FAB state variables
  Offset? _fabPosition;
  bool _isDragging = false;
  Offset? _dragStartFabPosition;
  Offset? _dragStartPoint;

  @override
  void initState() {
    super.initState();
    context.read<ManagerProductBloc>().add(LoadManagerProductsEvent());
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<NotificationBloc>().add(NotificationLoad(userId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý sản phẩm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: notifState.unreadCount > 0,
                  label: notifState.unreadCount > 99
                      ? const Text('99+')
                      : Text('${notifState.unreadCount}'),
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _fabPosition ??= Offset(
            constraints.maxWidth - 56 - 16,
            constraints.maxHeight - 56 - 16,
          );

          return Stack(
            children: [
              BlocConsumer<ManagerProductBloc, ManagerProductState>(
                listener: (context, state) {
                  if (state is ManagerProductOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } else if (state is ManagerProductError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: AppColors.error,
                      ),
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
                        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Danh sách sản phẩm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Quản lý kho hàng, giá bán và trạng thái hiển thị.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
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
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : _buildAdminProductList(products),
                      ),

                      _buildFooter(products.length),
                    ],
                  );
                },
              ),
              
              // Draggable FAB
              Positioned(
                left: _fabPosition!.dx,
                top: _fabPosition!.dy,
                child: _buildDraggableFAB(constraints),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
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
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Text(
                'Lọc theo:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Đang bán', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tạm ẩn', 'hidden'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final isHidden = !isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHidden
            ? AppColors.textHint.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 12,
            color: isHidden ? AppColors.textSecondary : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isHidden ? 'Tạm ẩn' : 'Hiển thị',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isHidden ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int totalStock) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (totalStock == 0) {
      bgColor = AppColors.error.withValues(alpha: 0.15);
      textColor = AppColors.error;
      icon = Icons.cancel_outlined;
      label = 'Hết hàng';
    } else if (totalStock <= 5) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
      label = 'Sắp hết: $totalStock';
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
      icon = Icons.inventory_2_outlined;
      label = 'Tồn: $totalStock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableFAB(BoxConstraints constraints) {
    return GestureDetector(
      onLongPressStart: (details) {
        setState(() {
          _isDragging = true;
          _dragStartFabPosition = _fabPosition;
          _dragStartPoint = details.globalPosition;
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_dragStartFabPosition != null && _dragStartPoint != null) {
          final delta = details.globalPosition - _dragStartPoint!;
          setState(() {
            double newX = _dragStartFabPosition!.dx + delta.dx;
            double newY = _dragStartFabPosition!.dy + delta.dy;
            
            // Keep within boundaries with padding of 16
            newX = newX.clamp(16.0, constraints.maxWidth - 56 - 16);
            newY = newY.clamp(16.0, constraints.maxHeight - 56 - 16);
            
            _fabPosition = Offset(newX, newY);
          });
        }
      },
      onLongPressEnd: (details) {
        setState(() {
          _isDragging = false;
          _dragStartFabPosition = null;
          _dragStartPoint = null;
        });
      },
      child: AnimatedScale(
        scale: _isDragging ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isDragging ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: FloatingActionButton(
            heroTag: 'manager-products-fab',
            onPressed: _isDragging
                ? null
                : () {
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
            elevation: _isDragging ? 12 : 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: AppColors.onPrimary, size: 28),
          ),
        ),
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                          child: Image.network(
                            product.images.isNotEmpty
                                ? product.images.first
                                : 'https://via.placeholder.com/150',
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isHidden
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStatusBadge(product.isActive),
                              const SizedBox(width: 8),
                              _buildStockBadge(totalStock),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Danh mục: ${product.category?.name ?? "Chưa phân loại"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(product.createdAt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textHint,
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
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
    );
  }
}
