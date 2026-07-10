import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../models/product_model.dart';
import '../../models/variant_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/product_service.dart';

class CartItemEditScreen extends StatefulWidget {
  const CartItemEditScreen({super.key});

  @override
  State<CartItemEditScreen> createState() => _CartItemEditScreenState();
}

class _CartItemEditScreenState extends State<CartItemEditScreen> {
  late CartItemModel _item;
  ProductModel? _product;
  List<VariantModel> _variants = [];
  List<String> _sizes = [];

  String? _selectedSize;
  String _selectedColorHex = '';
  int _quantity = 1;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  Future<void> _loadProduct() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! CartItemModel) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _item = args;
    final productId = _item.productId;
    if (productId.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _selectedSize = _item.size.isNotEmpty ? _item.size : null;
    _selectedColorHex = _item.variant?.colorHex ?? '';
    _quantity = _item.quantity;

    final productService = ProductService();
    final product = await productService.getProductById(productId);

    if (!mounted) return;

    if (product == null) {
      Navigator.pop(context);
      return;
    }

    // Ensure selected color hex is valid for the loaded product
    final loadedVariants = product.variants
        .where((v) => _selectedSize == null || v.size == _selectedSize)
        .toList();
    final validHexes = loadedVariants
        .map((v) => v.colorHex)
        .where((h) => h.isNotEmpty)
        .toSet()
        .toList();
    if (_selectedColorHex.isEmpty || !validHexes.contains(_selectedColorHex)) {
      _selectedColorHex = validHexes.isNotEmpty ? validHexes.first : '';
    }

    setState(() {
      _product = product;
      _variants = product.variants;
      _sizes = product.sizes;
      _isLoading = false;
    });
  }

  /// Unique color entries (hex → name) for the currently selected size.
  List<MapEntry<String, String>> get _uniqueColors {
    final seen = <String>{};
    final result = <MapEntry<String, String>>[];
    final src = _selectedSize == null
        ? _variants
        : _variants.where((v) => v.size == _selectedSize);
    for (final v in src) {
      if (v.colorHex.isNotEmpty && seen.add(v.colorHex)) {
        result.add(MapEntry(v.colorHex, v.color));
      }
    }
    return result;
  }

  String? get _selectedVariantId {
    final src = _selectedSize == null
        ? _variants
        : _variants.where((v) => v.size == _selectedSize);
    final match = src.cast<VariantModel?>().firstWhere(
          (v) =>
              v!.size == (_selectedSize ?? v.size) &&
              v.colorHex == _selectedColorHex,
          orElse: () => null,
        );
    return match?.id;
  }

  bool get _hasChanges {
    if (_quantity != _item.quantity) return true;
    if (_selectedSize != (_item.size.isNotEmpty ? _item.size : null)) return true;
    if (_selectedColorHex != (_item.variant?.colorHex ?? '')) return true;
    return false;
  }

  void _confirm() {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    final variantId = _selectedVariantId;
    if (variantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết size/màu này'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final cartBloc = context.read<CartBloc>();
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    final variantChanged = variantId != _item.variantId;
    if (variantChanged) {
      cartBloc.add(CartRemoveItem(_item.id));
      cartBloc.add(CartAddItem(userId, variantId, _quantity));
    } else if (_quantity != _item.quantity) {
      cartBloc.add(CartUpdateQuantity(_item.id, _quantity));
    }
    // Brief delay so the cart BLoC processes events before we pop
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(variantChanged ? 'Đã đổi sản phẩm' : 'Đã cập nhật số lượng'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isLoading ? 'Đang tải...' : (_product?.name ?? ''))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final product = _product!;
    final images = product.images;
    final displayImages = images.isNotEmpty ? images : [''];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                if (displayImages.first.isEmpty) {
                  return Container(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 80, color: AppColors.textHint),
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
                      child: Icon(Icons.image_outlined, size: 80, color: AppColors.textHint),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${product.price.toStringAsFixed(0)}đ',
                    style: AppTypography.price.copyWith(
                        color: AppColors.primary)),
                const SizedBox(height: 16),
                Text('Mô tả sản phẩm',
                    style: AppTypography.headlineSmall),
                const SizedBox(height: 8),
                Text(product.description.isNotEmpty
                        ? product.description
                        : 'Không có mô tả',
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                if (_sizes.isNotEmpty) ...[
                  Text('Chọn size',
                      style: AppTypography.headlineSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sizes.map((size) {
                      final active = size == _selectedSize;
                      return ChoiceChip(
                        label: Text(size),
                        selected: active,
                        onSelected: (_) {
                          setState(() {
                            _selectedSize = size;
                            final newColors = _uniqueColors;
                            if (newColors.isNotEmpty &&
                                !newColors.any((e) => e.key == _selectedColorHex)) {
                              _selectedColorHex = newColors.first.key;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                if (_uniqueColors.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Chọn màu sắc',
                      style: AppTypography.headlineSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _uniqueColors.map((entry) {
                      final active = entry.key == _selectedColorHex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorHex = entry.key),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseHexColor(entry.key),
                                border: Border.all(
                                  color: active ? AppColors.primary : AppColors.border,
                                  width: active ? 3 : 1.5,
                                ),
                                boxShadow: [
                                  if (entry.key.toUpperCase() == '#FFFFFF')
                                    BoxShadow(
                                      color: AppColors.shadow.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                    ),
                                ],
                              ),
                              child: active
                                  ? const Icon(Icons.check, size: 20, color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(entry.value,
                                style: AppTypography.caption.copyWith(
                                    color: active ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Số lượng',
                    style: AppTypography.headlineSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniButton(Icons.remove, () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_quantity',
                          style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w600)),
                    ),
                    _miniButton(Icons.add, () {
                      setState(() => _quantity++);
                    }),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _confirm,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary))
                        : Text(
                            _hasChanges ? 'Xác nhận thay đổi' : 'Quay lại',
                            style: AppTypography.button.copyWith(fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap) {
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

  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
