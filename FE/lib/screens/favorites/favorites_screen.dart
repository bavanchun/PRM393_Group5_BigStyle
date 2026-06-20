import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/wishlist/wishlist_bloc.dart';
import '../../blocs/wishlist/wishlist_event.dart';
import '../../blocs/wishlist/wishlist_state.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    context.read<WishlistBloc>().add(WishlistLoad(user?.id));
  }

  bool _isRealUserId(String? userId) {
    return userId != null && userId.isNotEmpty && !userId.startsWith('mock-');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final isLoggedIn = _isRealUserId(user?.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Yêu thích', style: AppTypography.headlineSmall),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: !isLoggedIn
          ? _buildLoginPrompt(context)
          : BlocBuilder<WishlistBloc, WishlistState>(
              builder: (context, state) {
                if (state.isLoading && state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.products.isEmpty) {
                  return _buildEmptyState();
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      imageUrl:
                          product.images.isNotEmpty ? product.images.first : '',
                      name: product.name,
                      price: product.price,
                      originalPrice: product.originalPrice,
                      sizes: product.sizes,
                      isWishlisted: state.contains(product.id),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/product-detail',
                        arguments: product.id,
                      ),
                      onWishlistToggle: () =>
                          context.read<WishlistBloc>().add(
                                WishlistToggle(
                                  userId: user!.id,
                                  productId: product.id,
                                ),
                              ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chưa có sản phẩm yêu thích',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đăng nhập để xem danh sách yêu thích',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}
