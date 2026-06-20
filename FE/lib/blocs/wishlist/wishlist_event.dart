import 'package:equatable/equatable.dart';

sealed class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

/// Load the signed-in user's wishlist. Passing a null/mock user clears it.
class WishlistLoad extends WishlistEvent {
  final String? userId;

  const WishlistLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Toggle one product in the wishlist (add if absent, remove if present).
class WishlistToggle extends WishlistEvent {
  final String userId;
  final String productId;

  const WishlistToggle({required this.userId, required this.productId});

  @override
  List<Object?> get props => [userId, productId];
}
