/// Reasonable email shape check: a non-empty local part (letters, digits,
/// `. + - _`), an `@`, and a dotted domain. Accepts `+alias` addresses (the
/// team's admin/manager test accounts use them); rejects `a@`, `@b`, and
/// anything without a dotted domain.
final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
  if (!_emailPattern.hasMatch(v.trim())) return 'Email không hợp lệ';
  return null;
}

/// Supabase's default minimum is 6 characters.
String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
  if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
  return null;
}
