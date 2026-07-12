import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/staggered_entrance.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts());
    context.read<ProductBloc>().add(ProductLoadFeatured());
    context.read<ProductBloc>().add(ProductLoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: StaggeredEntrance(
                      trigger: true,
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildSearchBar(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildHeroBanner(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: StaggeredEntrance(
                        trigger: state.categories.isNotEmpty,
                        index: 1,
                        child: _buildCategories(state),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: SectionHeader(
                      title: 'Sản phẩm nổi bật',
                      actionLabel: 'Xem tất cả',
                      onAction: () => Navigator.pushNamed(context, '/products'),
                    ),
                  ),
                ),
                if (state.isLoading)
                  _buildShimmerGrid()
                else if (state.error != null && state.featuredProducts.isEmpty)
                  _buildErrorSliver(state.error!)
                else if (state.featuredProducts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: Text('Chưa có sản phẩm nổi bật')),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = state.featuredProducts[index];
                        final imageUrl = product.images.isNotEmpty
                            ? product.images.first
                            : '';
                        final heroTag =
                            'product-${product.id}-home-featured-$index';
                        return StaggeredEntrance(
                          trigger:
                              !state.isLoading &&
                              state.featuredProducts.isNotEmpty,
                          index: 2,
                          child: ProductCard(
                            imageUrl: imageUrl,
                            name: product.name,
                            price: product.price,
                            originalPrice: product.originalPrice,
                            sizes: product.sizes,
                            soldCount: product.soldCount,
                            brandName: product.brandName,
                            heroTag: heroTag,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/product-detail',
                              arguments: {
                                'productId': product.id,
                                'heroTag': heroTag,
                                'imageUrl': imageUrl,
                              },
                            ),
                          ),
                        );
                      }, childCount: state.featuredProducts.length.clamp(0, 4)),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: SectionHeader(
                      title: 'Sản phẩm mới',
                      actionLabel: 'Xem tất cả',
                      onAction: () => Navigator.pushNamed(context, '/products'),
                    ),
                  ),
                ),
                if (state.isLoading)
                  _buildShimmerGrid()
                else if (state.error != null && state.products.isEmpty)
                  _buildErrorSliver(state.error!)
                else if (state.products.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: Text('Chưa có sản phẩm mới')),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = state.products[index];
                        final imageUrl = product.images.isNotEmpty
                            ? product.images.first
                            : '';
                        final heroTag =
                            'product-${product.id}-home-new_arrivals-$index';
                        return StaggeredEntrance(
                          trigger:
                              !state.isLoading && state.products.isNotEmpty,
                          index: 3,
                          child: ProductCard(
                            imageUrl: imageUrl,
                            name: product.name,
                            price: product.price,
                            originalPrice: product.originalPrice,
                            sizes: product.sizes,
                            soldCount: product.soldCount,
                            brandName: product.brandName,
                            heroTag: heroTag,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/product-detail',
                              arguments: {
                                'productId': product.id,
                                'heroTag': heroTag,
                                'imageUrl': imageUrl,
                              },
                            ),
                          ),
                        );
                      }, childCount: state.products.length),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  SliverToBoxAdapter _buildErrorSliver(String message) {
    return SliverToBoxAdapter(
      child: AppErrorState(
        message: message,
        padding: const EdgeInsets.all(AppSpacing.xl),
        iconSize: 48,
        onRetry: () {
          context.read<ProductBloc>().add(const LoadProducts());
          context.read<ProductBloc>().add(ProductLoadFeatured());
          context.read<ProductBloc>().add(ProductLoadCategories());
        },
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final name = authState.user?.fullName.trim() ?? '';
        final greeting = name.isEmpty
            ? 'Xin chào!'
            : 'Xin chào, ${name.split(' ').last}';
        final avatarUrl = authState.user?.avatarUrl;
        final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
        final initial = name.isNotEmpty
            ? name.substring(0, 1).toUpperCase()
            : '';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'BigStyle',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.secondary,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : (initial.isNotEmpty
                            ? Text(
                                initial,
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: AppColors.primary,
                              )),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppColors.textHint),
            const SizedBox(width: 12),
            Text(
              'Tìm kiếm sản phẩm...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.style,
              size: 140,
              color: AppColors.onPrimary.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BST MỚI',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bigger & Bolder',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giảm đến 30% đơn đầu tiên',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(ProductState state) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = state.categories[index];
          return PressableScale(
            onTap: () => Navigator.pushNamed(
              context,
              '/products',
              arguments: category.id,
            ),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checkroom,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.skeletonBase,
            highlightColor: AppColors.skeletonHighlight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          );
        }, childCount: 4),
      ),
    );
  }
}
