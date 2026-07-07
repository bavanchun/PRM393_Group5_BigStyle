/// Build a URL-safe slug from a Vietnamese name (product or category).
/// Strips diacritics, lowercases, and hyphenates. A short time-based suffix
/// keeps it unique against NOT NULL + unique `slug` constraints even when two
/// records share the same name.
String generateSlug(String name) {
  var slug = name.toLowerCase().trim();
  const diacriticGroups = {
    'a': 'àáảãạăằắẳẵặâầấẩẫậ',
    'e': 'èéẻẽẹêềếểễệ',
    'i': 'ìíỉĩị',
    'o': 'òóỏõọôồốổỗộơờớởỡợ',
    'u': 'ùúủũụưừứửữự',
    'y': 'ỳýỷỹỵ',
    'd': 'đ',
  };
  diacriticGroups.forEach((ascii, chars) {
    slug = slug.replaceAll(RegExp('[$chars]'), ascii);
  });
  slug = slug
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) slug = 'san-pham';
  final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  return '$slug-${stamp.substring(stamp.length - 4)}';
}
