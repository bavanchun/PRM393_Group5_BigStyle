import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/product_list/product_list_screen.dart';
import '../../screens/product_detail/product_detail_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/cart/cart_item_edit_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/checkout/payment_qr_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/orders/order_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/delivery/delivery_map_screen.dart';
import '../../screens/delivery/delivery_map_args.dart';
import '../../screens/manager/manager_shell.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/favorites/favorites_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(settings: settings, builder: (_) => const HomeScreen());
      case '/products':
        return MaterialPageRoute(settings: settings, builder: (_) => const ProductListScreen());
      case '/product-detail':
        return MaterialPageRoute(settings: settings, builder: (_) => const ProductDetailScreen());
      case '/cart':
        return MaterialPageRoute(settings: settings, builder: (_) => const CartScreen());
      case '/cart-item-edit':
        return MaterialPageRoute(settings: settings, builder: (_) => const CartItemEditScreen());
      case '/checkout':
        return MaterialPageRoute(settings: settings, builder: (_) => const CheckoutScreen());
      case '/payment-qr':
        return MaterialPageRoute(settings: settings, builder: (_) => const PaymentQrScreen());
      case '/orders':
        return MaterialPageRoute(settings: settings, builder: (_) => const OrdersScreen());
      case '/order-detail':
        return MaterialPageRoute(settings: settings, builder: (_) => const OrderDetailScreen());
      case '/profile':
        return MaterialPageRoute(settings: settings, builder: (_) => const ProfileScreen());
      case '/edit-profile':
        return MaterialPageRoute(settings: settings, builder: (_) => const EditProfileScreen());
      case '/chat':
        return MaterialPageRoute(settings: settings, builder: (_) => const ChatScreen());
      case '/notifications':
        return MaterialPageRoute(settings: settings, builder: (_) => const NotificationsScreen());
      case '/delivery-map':
        final deliveryArgs =
            DeliveryMapArgs.fromRouteArguments(settings.arguments);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DeliveryMapScreen(
            destination: deliveryArgs?.destination,
            destinationLabel: deliveryArgs?.destinationLabel,
            title: deliveryArgs?.title,
          ),
        );
      case '/manager':
        return MaterialPageRoute(settings: settings, builder: (_) => const ManagerShell());
      case '/admin':
        return MaterialPageRoute(settings: settings, builder: (_) => const AdminShell());
      case '/favorites':
        return MaterialPageRoute(settings: settings, builder: (_) => const FavoritesScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
