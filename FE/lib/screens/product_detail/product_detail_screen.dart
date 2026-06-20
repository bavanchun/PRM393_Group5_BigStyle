import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/product_detail/product_detail_bloc.dart';
import '../../blocs/product_detail/product_detail_event.dart';
import '../../blocs/product_detail/product_detail_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/variant_model.dart';
import '../../widgets/expandable_text.dart';
import 'size_guide_sheet.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productId = ModalRoute.of(context)?.settings.arguments as String?;
    if (productId != null) {
      context.read<ProductDetailBloc>().add(LoadProductDetail(productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final carouselHeight = screenHeight * 0.55;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                      final productId =
                          ModalRoute.of(context)?.settings.arguments as String?;
                      if (productId != null) {
                        context
                            .read<ProductDetailBloc>()
                            .add(LoadProductDetail(productId));
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
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        size: 20, color: AppColors.textPrimary),
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined,
                            size: 20, color: AppColors.textPrimary),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize:
                    (screenHeight - carouselHeight + 20) / screenHeight,
                minChildSize: 0.35,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
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
                                AppSpacing.md, 0, AppSpacing.md, 100),
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
                              _buildReviews(state),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCarousel(ProductDetailState state, List<String> images) {
    final displayImages = images.isNotEmpty ? images : [''];

    return Stack(
      children: [
        PageView.builder(
          itemCount: displayImages.length,
          onPageChanged: (index) => context
              .read<ProductDetailBloc>()
              .add(SetCurrentImageIndex(index)),
          itemBuilder: (context, index) {
            if (displayImages.first.isEmpty) {
              return Container(
                color: AppColors.secondary.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      size: 80, color: AppColors.textHint),
                ),
              );
            }
            return Image.network(
              displayImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.secondary.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      size: 80, color: AppColors.textHint),
                ),
              ),
            );
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
                  duration: const Duration(milliseconds: 200),
                  width: state.currentImageIndex == i ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: state.currentImageIndex == i
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.6),
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
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
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
          '${product.price.toStringAsFixed(0)}đ',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            '${product.originalPrice!.toStringAsFixed(0)}đ',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
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
              onTap: () =>
                  context.read<ProductDetailBloc>().add(SelectColor(hex)),
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: AppColors.primary)
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
              onTap: () =>
                  context.read<ProductDetailBloc>().add(SelectSize(size)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  size,
                  style: AppTypography.labelLarge.copyWith(
                    color:
                        isSelected ? Colors.white : AppColors.textPrimary,
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
        ExpandableText(
          text: product.description,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildReviews(ProductDetailState state) {
    if (state.reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đánh giá', style: AppTypography.headlineSmall),
            TextButton(
              onPressed: () {},
              child: Text(
                'Xem tất cả',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.reviews.map((review) => _buildReviewItem(review)),
      ],
    );
  }

  Widget _buildReviewItem(ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary,
                child: Text(
                  review.name.isNotEmpty ? review.name[0].toUpperCase() : '?',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name,
                        style:
                            AppTypography.labelLarge.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          review.rating.round(),
                          (_) => const Icon(Icons.star,
                              size: 14, color: AppColors.warning),
                        ),
                        const SizedBox(width: 6),
                        Text(review.date, style: AppTypography.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
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

  void _addToCart() {
    final detailState = context.read<ProductDetailBloc>().state;
    final product = detailState.product;
    if (product == null) return;

    // Auth guard — require a real (non-mock) authenticated user
    final user = context.read<AuthBloc>().state.user;
    if (user == null ||
        user.id.isEmpty ||
        user.id.startsWith('mock-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để mua hàng'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (detailState.selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn size'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Resolve variant: prefer size + color match, fallback to size-only, then first
    final selectedSize = detailState.selectedSize!;
    final selectedColor = detailState.selectedColor;

    VariantModel? variant = product.variants.cast<VariantModel?>().firstWhere(
          (v) => v!.size == selectedSize && v.colorHex == selectedColor,
          orElse: () => null,
        );
    variant ??= product.variants.cast<VariantModel?>().firstWhere(
          (v) => v!.size == selectedSize,
          orElse: () => null,
        );
    variant ??= product.variants.isNotEmpty ? product.variants.first : null;

    if (variant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm tạm hết hàng'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<CartBloc>().add(CartAddItem(user.id, variant.id, 1));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() {
    final state = context.read<ProductDetailBloc>().state;
    if (state.selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn size'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _addToCart();
    Navigator.pushNamed(context, '/cart');
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
