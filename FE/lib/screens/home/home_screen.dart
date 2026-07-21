import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';
import '../../models/product_model.dart';
import '../../providers/flash_sale_provider.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../utils/currency_format.dart';

// ---------------------------------------------------------------------------
// Banner model (mock — thay API sau nếu cần)
// ---------------------------------------------------------------------------
class _BannerItem {
  final String label;
  final String headline;
  final String sub;
  final List<Color> gradient;
  _BannerItem(this.label, this.headline, this.sub, this.gradient);
}

// ---------------------------------------------------------------------------
// HOME SCREEN
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Banner carousel ---
  late final PageController _bannerController;
  int _bannerPage = 0;
  Timer? _bannerTimer;
  final List<_BannerItem> _banners = [
    _BannerItem(
      'BST MỚI',
      'BIGGER\n& BOLDER',
      'Giảm đến 30% đơn đầu tiên',
      [AppColors.primary, AppColors.primaryDark],
    ),
    _BannerItem(
      'OVERSIZE COLLECTION',
      'GO BIG\nOR GO HOME',
      'Áo khoác oversize mới về',
      [const Color(0xFF1A1512), const Color(0xFF3D332E)],
    ),
    _BannerItem(
      'FLASH SALE',
      'UP TO\n50% OFF',
      'Chỉ hôm nay — số lượng có hạn',
      [const Color(0xFFB8562F), const Color(0xFF8C3E22)],
    ),
  ];

  // --- Quick filter chips ---
  final List<String> _quickFilters = [
    'Tất cả', 'Bán chạy', 'Áo', 'Quần', 'Phụ kiện', 'Giảm giá',
  ];
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts());
    context.read<ProductBloc>().add(ProductLoadFeatured());
    context.read<ProductBloc>().add(ProductLoadCategories());
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<NotificationBloc>().add(NotificationLoad(userId));
    }
    context.read<FlashSaleProvider>().init();

    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    context.read<FlashSaleProvider>().dispose();
    super.dispose();
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
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchBar(context)),
                SliverToBoxAdapter(child: _buildBannerCarousel()),
                SliverToBoxAdapter(child: _buildTrustBadges()),
                SliverToBoxAdapter(child: _buildCategories(state)),
                SliverToBoxAdapter(child: _buildQuickFilters()),
                SliverToBoxAdapter(child: _buildFlashSaleSection()),
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Sản phẩm nổi bật', onSeeAll: () {
                    Navigator.pushNamed(context, '/products', arguments: {'featured': true});
                  }),
                ),
                _buildFeaturedGrid(state),
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Sản phẩm mới', onSeeAll: () {
                    Navigator.pushNamed(context, '/products');
                  }),
                ),
                _buildNewProductsGrid(state),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // -------------------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------------------
  // -------------------------------------------------------------------------
  // 1. HEADER
  // -------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1512),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào!',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'BIGSTYLE',
                    style: AppTypography.displaySmall.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: const Color(0xFF1A1512),
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, notifState) {
                  return _buildIconBadge(
                    icon: Icons.notifications_outlined,
                    count: notifState.unreadCount,
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  );
                },
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBadge({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. SEARCH BAR
  // -------------------------------------------------------------------------
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/products'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textHint, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm kiếm sản phẩm...',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 3. HERO BANNER — carousel
  // -------------------------------------------------------------------------
  Widget _buildBannerCarousel() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _bannerPage = i),
              itemBuilder: (context, i) => _buildBannerCard(_banners[i]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final active = i == _bannerPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(_BannerItem banner) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        gradient: LinearGradient(
          colors: banner.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.style, size: 140, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    banner.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  banner.headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.sub,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 4. TRUST BADGES
  // -------------------------------------------------------------------------
  Widget _buildTrustBadges() {
    final items = [
      (Icons.local_shipping_outlined, 'Freeship\nđơn từ 299K'),
      (Icons.autorenew, 'Đổi trả\ntrong 7 ngày'),
      (Icons.verified_outlined, 'Cam kết\nchính hãng'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((item) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$1, size: 20, color: AppColors.primary),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 5. CATEGORIES — ảnh tròn
  // -------------------------------------------------------------------------
  Widget _buildCategories(ProductState state) {
    if (state.categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: state.categories.length,
        itemBuilder: (context, i) {
          final cat = state.categories[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/products', arguments: cat.id),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: cat.imageUrl != null
                              ? Image.network(
                                  cat.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.checkroom,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                )
                              : const Icon(Icons.checkroom, color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 6. QUICK FILTER CHIPS
  // -------------------------------------------------------------------------
  Widget _buildQuickFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _quickFilters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = i == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1A1512) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? const Color(0xFF1A1512) : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _quickFilters[i],
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlashSaleSection() {
    return Consumer<FlashSaleProvider>(
      builder: (context, provider, _) {
        if (provider.hasEnded || (provider.campaign == null && !provider.isLoading)) {
          return const SizedBox.shrink();
        }

        final h = provider.remaining.inHours.toString().padLeft(2, '0');
        final m = (provider.remaining.inMinutes % 60).toString().padLeft(2, '0');
        final s = (provider.remaining.inSeconds % 60).toString().padLeft(2, '0');

        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.primary, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          'FLASH SALE',
                          style: AppTypography.displaySmall.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1512),
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1512),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$h:$m:$s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 275,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.campaign?.products.length ?? 0,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final product = provider.campaign!.products[i];
                    return SizedBox(
                      width: 150,
                      child: _FlashSaleCard(product: product),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // SECTION HEADER dùng chung
  // -------------------------------------------------------------------------
  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.displaySmall.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1512),
              height: 1.05,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'Xem tất cả',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // FEATURED PRODUCTS GRID
  // -------------------------------------------------------------------------
  Widget _buildFeaturedGrid(ProductState state) {
    if (state.isLoading) return _buildShimmerGrid();
    if (state.error != null && state.featuredProducts.isEmpty) {
      return _buildErrorSliver(state.error!);
    }
    if (state.featuredProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Chưa có sản phẩm nổi bật')),
        ),
      );
    }
    final products = state.featuredProducts.take(4).toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // NEW PRODUCTS GRID
  // -------------------------------------------------------------------------
  Widget _buildNewProductsGrid(ProductState state) {
    if (state.isLoading) return _buildShimmerGrid();
    if (state.error != null && state.products.isEmpty) {
      return _buildErrorSliver(state.error!);
    }
    if (state.products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Chưa có sản phẩm mới')),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ProductCard(product: state.products[i]),
          childCount: state.products.length,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SHIMMER LOADING
  // -------------------------------------------------------------------------
  SliverPadding _buildShimmerGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          );
        }, childCount: 4),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // ERROR STATE
  // -------------------------------------------------------------------------
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
}

// ---------------------------------------------------------------------------
// MOCK PRODUCT WRAPPER (dùng cho flash sale - tách biệt với real data)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// PRODUCT CARD — dùng cho grid (featured / new products)
// ---------------------------------------------------------------------------
class _ProductCard extends StatefulWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _wishlisted = false;

  String _id() => widget.product.id;
  String _name() => widget.product.name;
  String? _brand() => widget.product is ProductModel ? (widget.product as ProductModel).brandName : widget.product.brand;
  String _imageUrl() {
    if (widget.product is ProductModel) {
      final p = widget.product as ProductModel;
      return p.images.isNotEmpty ? p.images.first : '';
    }
    return widget.product.imageUrl;
  }

  int _price() {
    if (widget.product is ProductModel) return (widget.product as ProductModel).price.toInt();
    return widget.product.price;
  }

  int? _originalPrice() {
    if (widget.product is ProductModel) return (widget.product as ProductModel).originalPrice?.toInt();
    return widget.product.originalPrice;
  }

  bool _onSale() {
    final orig = _originalPrice();
    return orig != null && orig > _price();
  }

  List<String> _sizes() {
    if (widget.product is ProductModel) return (widget.product as ProductModel).sizes;
    return widget.product.sizes;
  }

  int _sold() {
    if (widget.product is ProductModel) return (widget.product as ProductModel).soldCount;
    return widget.product.sold;
  }

  double _rating() {
    if (widget.product is ProductModel) return (widget.product as ProductModel).rating ?? 0;
    return widget.product.rating;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: _id()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Ảnh ----
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _imageUrl(),
                      fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        child: const Icon(Icons.checkroom, color: AppColors.textHint, size: 32),
                      ),
                    ),
                    if (_onSale())
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SALE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _wishlisted = !_wishlisted),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                          child: Icon(
                            _wishlisted ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: _wishlisted ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ---- Thông tin ----
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_brand() != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _brand()!,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    _name(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFE0A845)),
                      const SizedBox(width: 2),
                      Text(
                        _rating().toStringAsFixed(1),
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                      if (_sold() > 0) ...[
                        Icon(Icons.shopping_bag_outlined, size: 11, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          'Đã bán ${_sold()}',
                          style: AppTypography.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_sizes().isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: _sizes().take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppSpacing.microRadius),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            s,
                            style: AppTypography.caption.copyWith(fontSize: 9, color: AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          _formatPrice(_price()),
                          style: AppTypography.priceSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (_onSale()) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatPrice(_originalPrice()!),
                            style: AppTypography.caption.copyWith(
                              fontSize: 9,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) => formatVnd(price);
}

// ---------------------------------------------------------------------------
// FLASH SALE CARD — dùng riêng cho FlashSaleProduct
// ---------------------------------------------------------------------------
class _FlashSaleCard extends StatelessWidget {
  final FlashSaleProduct product;
  const _FlashSaleCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        child: const Icon(Icons.checkroom, color: AppColors.textHint, size: 32),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (product.isSoldOut)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hết hàng',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: product.soldPercent,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã bán ${product.soldQty}/${product.stockQty}',
                    style: AppTypography.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatPriceVnd(product.salePrice),
                          style: AppTypography.priceSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatPriceVnd(product.originalPrice),
                          style: AppTypography.caption.copyWith(
                            fontSize: 9,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPriceVnd(int price) => formatVnd(price);
}
