import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme/app_colors.dart';
import '../../utils/currency_format.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/product_detail/product_detail_bloc.dart';
import '../../blocs/product_detail/product_detail_event.dart';
import '../../blocs/product_detail/product_detail_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/wishlist/wishlist_bloc.dart';
import '../../blocs/wishlist/wishlist_state.dart';
import '../../blocs/wishlist/wishlist_actions.dart';
import '../../blocs/review/review_bloc.dart';
import '../../blocs/review/review_event.dart';
import '../../blocs/review/review_state.dart';
import '../../models/variant_model.dart';
import '../../config/theme/app_motion.dart';
import '../../utils/haptics.dart';
import '../../widgets/expandable_text.dart';
import '../../widgets/staggered_entrance.dart';
import 'product_detail_args.dart';
import 'product_detail_skeleton.dart';
import 'product_review_section.dart';
import 'review_editor_sheet.dart';
import 'size_guide_sheet.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _loadedProductId;
  // Hero context from the tapped card (list/home) — null when navigated
  // without one (favorites, deep link), which just disables the Hero wrap.
  String? _heroTag;
  String? _heroImageUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ProductDetailArgs.fromRouteArguments(
      ModalRoute.of(context)?.settings.arguments,
    );
    final productId = args?.productId;
    if (productId != null && productId != _loadedProductId) {
      _loadedProductId = productId;
      _heroTag = args?.heroTag;
      _heroImageUrl = args?.imageUrl;
      context.read<ProductDetailBloc>().add(LoadProductDetail(productId));
      final user = context.read<AuthBloc>().state.user;
      context.read<ReviewBloc>().add(
        ReviewLoad(
          productId,
          userId: _isRealUserId(user?.id) ? user!.id : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final carouselHeight = screenHeight * 0.55;

    return BlocListener<ReviewBloc, ReviewState>(
      listenWhen: (previous, current) =>
          !previous.submissionSucceeded && current.submissionSucceeded,
      listener: (context, state) {
        final productId = state.productId;
        if (productId != null) {
          context.read<ProductDetailBloc>().add(LoadProductDetail(productId));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state.isLoading) {
              // The destination Hero must exist during the whole async load
              // — otherwise the flight from the card silently no-ops, since
              // the real carousel isn't in the tree yet.
              if (_heroTag != null &&
                  _heroImageUrl != null &&
                  _heroImageUrl!.isNotEmpty) {
                return Stack(
                  children: [
                    ProductDetailSkeleton(carouselHeight: carouselHeight),
                    SizedBox(
                      height: carouselHeight,
                      width: double.infinity,
                      child: Hero(
                        tag: _heroTag!,
                        child: Image.network(
                          _heroImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ProductDetailSkeleton(carouselHeight: carouselHeight);
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error!, style: AppTypography.bodyMedium),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        final productId = _loadedProductId;
                        if (productId != null) {
                          context.read<ProductDetailBloc>().add(
                            LoadProductDetail(productId),
                          );
                        }
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final product = state.product;
            if (product == null) return const SizedBox.shrink();

            return Stack(
              children: [
                SizedBox(
                  height: carouselHeight,
                  child: _buildCarousel(state, product.images),
                ),
                Positioned(
                  top: topPadding + 8,
                  left: 16,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surface,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding + 8,
                  right: 16,
                  child: Row(
                    children: [
                      BlocBuilder<WishlistBloc, WishlistState>(
                        builder: (context, wishlist) {
                          final isWishlisted = wishlist.contains(product.id);
                          return CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.surface,
                            child: IconButton(
                              icon: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: isWishlisted
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                              onPressed: () =>
                                  toggleWishlist(context, product.id),
                              padding: EdgeInsets.zero,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surface,
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    '${product.name} - ${formatVnd(product.price)}\n'
                                    'Xem sản phẩm trên BigStyle!',
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                StaggeredEntrance(
                  trigger: true,
                  index: 0,
                  child: DraggableScrollableSheet(
                    initialChildSize:
                        (screenHeight - carouselHeight + 20) / screenHeight,
                    minChildSize: 0.35,
                    maxChildSize: 0.85,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  0,
                                  AppSpacing.md,
                                  100,
                                ),
                                children: [
                                  _buildProductName(state),
                                  const SizedBox(height: 8),
                                  _buildRating(state),
                                  const SizedBox(height: 12),
                                  _buildPrice(state),
                                  const SizedBox(height: 20),
                                  _buildSizeGuideButton(),
                                  const SizedBox(height: 24),
                                  _buildColorSelector(state),
                                  const SizedBox(height: 24),
                                  _buildSizeSelector(state),
                                  const SizedBox(height: 24),
                                  _buildDescription(state),
                                  const SizedBox(height: 24),
                                  BlocBuilder<ReviewBloc, ReviewState>(
                                    builder: (context, reviewState) {
                                      return ProductReviewSection(
                                        isLoading: reviewState.isLoading,
                                        reviews: reviewState.reviews,
                                        myReview: reviewState.myReview,
                                        canReview: reviewState.canReview,
                                        error: reviewState.error,
                                        onWrite: () =>
                                            _openReviewEditor(product.id),
                                        onReload: () =>
                                            _reloadReviews(product.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildCarousel(ProductDetailState state, List<String> images) {
    final displayImages = images.isNotEmpty ? images : [''];

    return Stack(
      children: [
        PageView.builder(
          itemCount: displayImages.length,
          onPageChanged: (index) => context.read<ProductDetailBloc>().add(
            SetCurrentImageIndex(index),
          ),
          itemBuilder: (context, index) {
            if (displayImages.first.isEmpty) {
              return Container(
                color: AppColors.secondary.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: AppColors.textHint,
                  ),
                ),
              );
            }
            final image = Image.network(
              displayImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.secondary.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            );
            // Only page 0 matches the card's imageUrl (images.first) — the
            // tag the tapped card actually flew from.
            if (index == 0 && _heroTag != null) {
              return Hero(tag: _heroTag!, child: image);
            }
            return image;
          },
        ),
        if (displayImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayImages.length, (i) {
                return AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  width: state.currentImageIndex == i ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: state.currentImageIndex == i
                        ? AppColors.primary
                        : AppColors.onPrimary.withValues(alpha: 0.6),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildProductName(ProductDetailState state) {
    return Text(
      state.product!.name,
      style: AppTypography.displaySmall.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildRating(ProductDetailState state) {
    final product = state.product!;
    final rating = product.rating ?? 0;
    final count = product.reviewCount;

    return Row(
      children: [
        Icon(Icons.star, size: 18, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count đánh giá)',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(ProductDetailState state) {
    final product = state.product!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatVnd(product.price),
          style: AppTypography.price.copyWith(fontSize: 24),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            formatVnd(product.originalPrice!),
            style: AppTypography.caption.copyWith(
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${product.discountPercent.round()}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSizeGuideButton() {
    return GestureDetector(
      onTap: () {
        final state = context.read<ProductDetailBloc>().state;
        final sizes = state.product?.sizes ?? [];
        SizeGuideSheet.show(context, sizes: sizes);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.straighten, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Hướng dẫn chọn size',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  /// Colors derived from product variants (distinct colorHex values).
  Widget _buildColorSelector(ProductDetailState state) {
    final product = state.product!;
    // Distinct color hex values from loaded variants
    final colorHexList = product.variants
        .map((v) => v.colorHex)
        .where((h) => h.isNotEmpty)
        .toSet()
        .toList();

    if (colorHexList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn màu sắc', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: colorHexList.map((hex) {
            final color = _parseHexColor(hex);
            final isSelected = state.selectedColor == hex;
            return GestureDetector(
              onTap: () {
                Haptics.selection();
                context.read<ProductDetailBloc>().add(SelectColor(hex));
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    if (hex.toUpperCase() == '#FFFFFF')
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.primary,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSizeSelector(ProductDetailState state) {
    final product = state.product!;
    if (product.sizes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn size', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.sizes.map((size) {
            final isSelected = state.selectedSize == size;
            return GestureDetector(
              onTap: () {
                Haptics.selection();
                context.read<ProductDetailBloc>().add(SelectSize(size));
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  size,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription(ProductDetailState state) {
    final product = state.product!;
    if (product.description.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mô tả sản phẩm', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        ExpandableText(text: product.description, maxLines: 3),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _addToCart,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Thêm vào giỏ',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _buyNow,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Text(
                        'Mua ngay',
                        style: AppTypography.button.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Adds the currently selected variant to the cart.
  ///
  /// Returns `true` only when an item was actually added (i.e. not an
  /// auth-redirect, validation bail-out, or out-of-stock variant) — used by
  /// [_buyNow] to decide whether it's safe to navigate to the cart.
  Future<bool> _addToCart({bool showSnackbar = true}) async {
    final detailState = context.read<ProductDetailBloc>().state;
    final product = detailState.product;
    if (product == null) return false;

    // Auth guard — require a real (non-mock) authenticated user
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.id.isEmpty || user.id.startsWith('mock-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để mua hàng'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return false;
    }

    final hasSizes = product.sizes.isNotEmpty;
    if (hasSizes && detailState.selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn size'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final hasColors = product.variants.any((v) => v.colorHex.isNotEmpty);
    if (hasColors && detailState.selectedColor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn màu sắc'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Resolve variant: must match BOTH the selected size AND selected color.
    // No size-only or `.first` fallback — those silently add a different
    // color/size than what the user picked.
    final selectedSize = detailState.selectedSize!;
    final selectedColor = detailState.selectedColor;

    final variant = product.variants.cast<VariantModel?>().firstWhere(
      (v) => v!.size == selectedSize && v.colorHex == selectedColor,
      orElse: () => null,
    );

    if (variant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết size/màu này'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Fire success feedback (haptic + snackbar) only once the cart bloc
    // confirms the add — never on the tap itself, so an aborted/failed add
    // (guards above, or a failed/timed-out request) never plays "success".
    //
    // Gated on this variant's own quantity, not items.length: the server
    // merges into the existing row when the variant is already in the cart
    // (cart_service.dart addToCart), so a repeat add of the same variant
    // leaves items.length unchanged even though it succeeded.
    final cartBloc = context.read<CartBloc>();
    int quantityOf(CartState s) => s.items
        .where((i) => i.variantId == variant.id)
        .fold(0, (sum, i) => sum + i.quantity);
    final beforeQty = quantityOf(cartBloc.state);
    cartBloc.add(CartAddItem(user.id, variant.id, 1));

    bool added = false;
    try {
      final result = await cartBloc.stream
          .firstWhere((s) => quantityOf(s) > beforeQty || s.error != null)
          .timeout(const Duration(seconds: 5));
      added = result.error == null;
    } catch (_) {
      added = false;
    }
    if (!mounted) return added;

    if (!added) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm vào giỏ hàng thất bại'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    Haptics.success();
    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm vào giỏ hàng'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
    return true;
  }

  Future<void> _buyNow() async {
    final state = context.read<ProductDetailBloc>().state;
    final product = state.product;
    if (product == null) return;

    final hasSizes = product.sizes.isNotEmpty;
    if (hasSizes && state.selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn size'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final hasColors = product.variants.any((v) => v.colorHex.isNotEmpty);
    if (hasColors && state.selectedColor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn màu sắc'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // _addToCart already waits for the CartBloc to confirm before resolving.
    final added = await _addToCart(showSnackbar: false);
    if (!added || !mounted) return;
    Navigator.pushNamed(context, '/cart');
  }

  Future<void> _openReviewEditor(String productId) async {
    final user = context.read<AuthBloc>().state.user;
    if (!_isRealUserId(user?.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để viết đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }
    final userId = user!.id;

    final reviewBloc = context.read<ReviewBloc>();
    var reviewState = reviewBloc.state;
    if (reviewState.productId != productId || reviewState.userId != userId) {
      final loaded = reviewBloc.stream.firstWhere(
        (state) =>
            state.productId == productId &&
            state.userId == userId &&
            !state.isLoading,
      );
      reviewBloc.add(ReviewLoad(productId, userId: userId));
      reviewState = await loaded;
    } else if (reviewState.isLoading) {
      reviewState = await reviewBloc.stream.firstWhere(
        (state) => !state.isLoading,
      );
    }
    if (!mounted) return;

    final orderItemId = reviewState.eligibleOrderItemId;
    if (orderItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mua và nhận hàng để đánh giá sản phẩm này'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final saved = await ReviewEditorSheet.show(
      context,
      productId: productId,
      userId: userId,
      orderItemId: orderItemId,
      existingReview: reviewState.myReview,
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu đánh giá')));
  }

  void _reloadReviews(String productId) {
    final user = context.read<AuthBloc>().state.user;
    context.read<ReviewBloc>().add(
      ReviewLoad(productId, userId: _isRealUserId(user?.id) ? user!.id : null),
    );
  }

  bool _isRealUserId(String? userId) {
    return userId != null && userId.isNotEmpty && !userId.startsWith('mock-');
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
