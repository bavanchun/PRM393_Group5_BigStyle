import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import 'wishlist_bloc.dart';
import 'wishlist_event.dart';

/// Auth-guarded wishlist toggle shared by every product card / detail heart.
/// A non-authenticated (or mock) user is bounced to the login screen instead
/// of writing to Supabase, where RLS would reject the row anyway.
void toggleWishlist(BuildContext context, String productId) {
  final userId = context.read<AuthBloc>().state.user?.id;
  if (userId == null || userId.isEmpty || userId.startsWith('mock-')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng đăng nhập để dùng danh sách yêu thích'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushNamed(context, '/login');
    return;
  }
  context.read<WishlistBloc>().add(
        WishlistToggle(userId: userId, productId: productId),
      );
}
