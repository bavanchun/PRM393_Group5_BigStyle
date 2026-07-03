import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'config/supabase/supabase_config.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'blocs/product_detail/product_detail_bloc.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/checkout/checkout_bloc.dart';
import 'blocs/order/order_bloc.dart';
import 'blocs/notification/notification_bloc.dart';
import 'blocs/chat/chat_bloc.dart';
import 'blocs/manager/manager_bloc.dart';
import 'blocs/review/review_bloc.dart';
import 'blocs/wishlist/wishlist_bloc.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';
import 'services/review_service.dart';
import 'services/wishlist_service.dart';
import 'services/admin_service.dart';

import 'blocs/manager_product/manager_product_bloc.dart';
import 'blocs/admin/admin_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await supa.Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const BigStyleApp());
}

class BigStyleApp extends StatefulWidget {
  const BigStyleApp({super.key});

  @override
  State<BigStyleApp> createState() => _BigStyleAppState();
}

class _BigStyleAppState extends State<BigStyleApp> {
  StreamSubscription<supa.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final supabase = supa.Supabase.instance.client;

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (!mounted) return;

      if (event == supa.AuthChangeEvent.signedOut) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          // Only navigate — do NOT re-dispatch SignOutEvent (causes infinite loop)
          Navigator.of(ctx).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } else if (event == supa.AuthChangeEvent.tokenRefreshed) {
        debugPrint('Session: Token refreshed');
      } else if (session == null) {
        debugPrint('Session: No active session');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: productService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(AuthService(), GoogleAuthService()),
          ),
          BlocProvider(create: (_) => ProductBloc(productService)),
          BlocProvider(create: (_) => ProductDetailBloc(productService)),
          BlocProvider(create: (_) => ManagerProductBloc(productService)),
          BlocProvider(create: (_) => CartBloc(CartService())),
          BlocProvider(create: (_) => OrderBloc(OrderService())),
          BlocProvider(
            create: (ctx) => CheckoutBloc(OrderService(), CartService()),
          ),
          BlocProvider(create: (_) => NotificationBloc(NotificationService())),
          BlocProvider(create: (_) => ChatBloc(ChatService())),
          BlocProvider(create: (_) => ManagerBloc(OrderService())),
          BlocProvider(create: (_) => ReviewBloc(ReviewService())),
          BlocProvider(create: (_) => WishlistBloc(WishlistService())),
          BlocProvider(create: (_) => AdminBloc(AdminService())),
        ],
        child: MaterialApp(
          title: 'BigStyle',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: '/',
          onGenerateRoute: AppRouter.generateRoute,
          navigatorKey: navigatorKey,
        ),
      ),
    );
  }
}

// Global navigator key for auth listener
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
