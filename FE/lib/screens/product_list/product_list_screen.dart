import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../models/category_model.dart';
import '../../widgets/product_card.dart';
import '../../widgets/app_error_state.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = [
    'Tất cả',
    'Đầm',
    'Áo',
    'Quần',
    'Size XL',
    'Size 2XL',
    'Size 3XL',
    'Mới về',
    'Sale',
  ];
  bool _appliedArg = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts());
    context.read<ProductBloc>().add(const ProductLoadCategories());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedArg) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _appliedArg = true;
      final categories = context.read<ProductBloc>().state.categories;
      CategoryModel? matched;
      for (final c in categories) {
        if (c.id == args) {
          matched = c;
          break;
        }
      }
      setState(() => _selectedFilter = matched?.name ?? 'Tất cả');
      context.read<ProductBloc>().add(
        FilterByCategory(args, matched?.name ?? args),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Bộ sưu tập', style: AppTypography.headlineLarge),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_outlined, color: AppColors.textPrimary),
          onPressed: _showSortSheet,
        ),
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final count = state.totalQuantity;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Tìm váy, áo, quần...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ProductBloc>().add(const SearchProducts(''));
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            context.read<ProductBloc>().add(SearchProducts(value));
          },
          onChanged: (value) {
            if (value.isEmpty) {
              context.read<ProductBloc>().add(const SearchProducts(''));
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final label = _filters[index];
              final isSelected = _selectedFilter == label;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = label);
                  _onFilterSelected(label);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildShimmerGrid();
        }

        final products = state.filteredProducts;

        if (state.error != null && products.isEmpty) {
          return Center(
            child: AppErrorState(
              message: state.error!,
              onRetry: () {
                context.read<ProductBloc>().add(const LoadProducts());
                context.read<ProductBloc>().add(const ProductLoadCategories());
              },
            ),
          );
        }

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProductBloc>().add(const LoadProducts());
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              8,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.58,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                imageUrl: product.images.isNotEmpty ? product.images.first : '',
                name: product.name,
                price: product.price,
                originalPrice: product.originalPrice,
                sizes: product.sizes,
                soldCount: product.soldCount,
                brandName: product.brandName,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/product-detail',
                  arguments: product.id,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        8,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Không tìm thấy sản phẩm phù hợp',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onFilterSelected(String label) {
    switch (label) {
      case 'Tất cả':
        context.read<ProductBloc>().add(const FilterByCategory(null, 'all'));
        context.read<ProductBloc>().add(const FilterBySize(null));
        context.read<ProductBloc>().add(const ToggleSaleOnly(false));
      case 'Đầm':
      case 'Áo':
      case 'Quần':
        final categories = context.read<ProductBloc>().state.categories;
        CategoryModel? matched;
        for (final c in categories) {
          if (c.name == label) {
            matched = c;
            break;
          }
        }
        context.read<ProductBloc>().add(
          FilterByCategory(matched?.id ?? label, label),
        );
        context.read<ProductBloc>().add(const FilterBySize(null));
        context.read<ProductBloc>().add(const ToggleSaleOnly(false));
      case 'Size XL':
      case 'Size 2XL':
      case 'Size 3XL':
        // Chips are single-select — a size facet clears category + sale so only
        // one dimension is ever active.
        context.read<ProductBloc>().add(const FilterByCategory(null, 'all'));
        context.read<ProductBloc>().add(const ToggleSaleOnly(false));
        context.read<ProductBloc>().add(
          FilterBySize(label.replaceFirst('Size ', '')),
        );
      case 'Mới về':
        context.read<ProductBloc>().add(const SortProducts('newest'));
        context.read<ProductBloc>().add(const FilterBySize(null));
        context.read<ProductBloc>().add(const ToggleSaleOnly(false));
      case 'Sale':
        context.read<ProductBloc>().add(const FilterByCategory(null, 'all'));
        context.read<ProductBloc>().add(const FilterBySize(null));
        context.read<ProductBloc>().add(const ToggleSaleOnly(true));
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Sắp xếp theo', style: AppTypography.headlineMedium),
              const SizedBox(height: 20),
              ...[
                'Mới nhất',
                'Giá: Thấp đến cao',
                'Giá: Cao đến thấp',
                'Tên A-Z',
              ].map(
                (option) => ListTile(
                  title: Text(option, style: AppTypography.bodyMedium),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    switch (option) {
                      case 'Mới nhất':
                        context.read<ProductBloc>().add(
                          const SortProducts('newest'),
                        );
                      case 'Giá: Thấp đến cao':
                        context.read<ProductBloc>().add(
                          const SortProducts('price-asc'),
                        );
                      case 'Giá: Cao đến thấp':
                        context.read<ProductBloc>().add(
                          const SortProducts('price-desc'),
                        );
                      case 'Tên A-Z':
                        context.read<ProductBloc>().add(
                          const SortProducts('name'),
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
