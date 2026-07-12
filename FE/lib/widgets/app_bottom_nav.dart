import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_motion.dart';
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
          0,
          (sum, item) => sum + item.quantity,
        );
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.06),
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
                  selectedLabelStyle: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                  ),
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
                      icon: _CartTab(count: cartCount, active: false),
                      activeIcon: _CartTab(count: cartCount, active: true),
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
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

/// Cart tab icon+badge, isolated so its scale-pop animation is local state
/// (no GlobalKey — AppBottomNav is instantiated fresh per screen, and two
/// instances can be mounted at once during a page transition).
class _CartTab extends StatefulWidget {
  final int count;
  final bool active;

  const _CartTab({required this.count, required this.active});

  @override
  State<_CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<_CartTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.fast);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    // No pop on initial mount, even if count > 0 (e.g. cart already had
    // items from a prior session/screen) — AppBottomNav is instantiated
    // fresh per screen, so only a genuine increase observed *while this
    // instance is mounted* (via didUpdateWidget, incl. its own 0->1) pops.
  }

  @override
  void didUpdateWidget(covariant _CartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseIcon = Icon(
      widget.active ? Icons.shopping_bag : Icons.shopping_bag_outlined,
    );
    final icon = widget.count > 0
        ? Badge(
            label: Text(
              widget.count > 99 ? '99+' : '${widget.count}',
              style: const TextStyle(fontSize: 10),
            ),
            child: baseIcon,
          )
        : baseIcon;
    return ScaleTransition(scale: _scale, child: icon);
  }
}
