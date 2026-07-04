import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool showBadge;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final cartCount = (state).items.fold<int>(
            0, (sum, item) => sum + item.quantity);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) => _onTap(context, index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textHint,
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  selectedLabelStyle: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary, fontSize: 11),
                  unselectedLabelStyle: AppTypography.labelSmall
                      .copyWith(fontSize: 11),
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Trang chủ',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.explore_outlined),
                      activeIcon: Icon(Icons.explore),
                      label: 'Khám phá',
                    ),
                    BottomNavigationBarItem(
                      icon: cartCount > 0
                          ? Badge(
                              label: Text(
                                cartCount > 99 ? '99+' : '$cartCount',
                                style: const TextStyle(fontSize: 10),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined),
                            )
                          : const Icon(Icons.shopping_bag_outlined),
                      activeIcon: cartCount > 0
                          ? Badge(
                              label: Text(
                                cartCount > 99 ? '99+' : '$cartCount',
                                style: const TextStyle(fontSize: 10),
                              ),
                              child: const Icon(Icons.shopping_bag),
                            )
                          : const Icon(Icons.shopping_bag),
                      label: 'Giỏ hàng',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      activeIcon: Icon(Icons.receipt_long),
                      label: 'Đơn hàng',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: 'Cá nhân',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
      case 1:
        Navigator.pushNamed(context, '/products');
      case 2:
        Navigator.pushNamed(context, '/cart');
      case 3:
        Navigator.pushNamed(context, '/orders');
      case 4:
        Navigator.pushNamed(context, '/profile');
    }
  }
}
