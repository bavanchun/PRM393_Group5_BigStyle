/// Arguments passed to [ProductDetailScreen]. Accepts either the legacy
/// plain-String product id (favorites, deep links) or a Map carrying a
/// Hero context (list/home cards) — the Hero fields are optional so the
/// screen degrades to a plain (non-Hero) navigation when absent.
class ProductDetailArgs {
  final String productId;
  final String? heroTag;
  final String? imageUrl;

  const ProductDetailArgs({
    required this.productId,
    this.heroTag,
    this.imageUrl,
  });

  static ProductDetailArgs? fromRouteArguments(Object? args) {
    if (args is String) return ProductDetailArgs(productId: args);
    if (args is Map) {
      final id = args['productId'] as String?;
      if (id == null) return null;
      return ProductDetailArgs(
        productId: id,
        heroTag: args['heroTag'] as String?,
        imageUrl: args['imageUrl'] as String?,
      );
    }
    return null;
  }
}
