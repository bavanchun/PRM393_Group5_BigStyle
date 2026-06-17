import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../widgets/size_selector.dart';
import '../../widgets/app_button.dart';
import '../../models/cart_item_model.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productId = ModalRoute.of(context)?.settings.arguments as String;
    context.read<ProductBloc>().add(ProductLoadDetail(productId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          final product = state.selectedProduct;
          if (state.isLoading || product == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageCarousel(product.images),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.category != null)
                        Text(
                          product.category!.name,
                          style: AppTypography.caption,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        style: AppTypography.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(0)}đ',
                            style: AppTypography.price,
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${product.originalPrice!.toStringAsFixed(0)}đ',
                              style: AppTypography.bodyMedium.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${product.discountPercent.round()}%',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Chọn size',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      SizeSelector(
                        sizes: product.sizes,
                        selectedSize: _selectedSize,
                        onSelected: (size) =>
                            setState(() => _selectedSize = size),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Mô tả sản phẩm',
                            style: AppTypography.headlineSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Số lượng', style: AppTypography.headlineSmall),
                          Row(
                            children: [
                              _quantityButton(Icons.remove, () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              }),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_quantity',
                                  style: AppTypography.headlineSmall,
                                ),
                              ),
                              _quantityButton(Icons.add, () {
                                setState(() => _quantity++);
                              }),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: AppButton(
            label: 'Thêm vào giỏ hàng',
            icon: Icons.shopping_bag_outlined,
            onPressed: _addToCart,
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.secondary.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 80, color: AppColors.textHint),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          items: images.map((url) {
            return Image.network(url, fit: BoxFit.cover, width: double.infinity);
          }).toList(),
          options: CarouselOptions(
            height: 350,
            viewportFraction: 1,
            onPageChanged: (index, _) =>
                setState(() => _currentImageIndex = index),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == entry.key
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.5),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  void _addToCart() {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn size')),
      );
      return;
    }

    final state = context.read<ProductBloc>().state;
    final product = state.selectedProduct!;

    context.read<CartBloc>().add(CartAddItem(
      CartItemModel(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        product: product,
        size: _selectedSize!,
        quantity: _quantity,
        addedAt: DateTime.now(),
      ),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
