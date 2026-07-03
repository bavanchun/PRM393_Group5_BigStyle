import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'config/supabase/supabase_config.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';
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
import 'blocs/payment/payment_bloc.dart';
import 'blocs/cart/cart_event.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';
import 'services/review_service.dart';
import 'services/wishlist_service.dart';
import 'services/payment_service.dart';

import 'blocs/manager_product/manager_product_bloc.dart';
import 'blocs/manager_category/manager_category_bloc.dart';
import 'blocs/manager_voucher/manager_voucher_bloc.dart';
import 'services/category_service.dart';
import 'services/voucher_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const BigStyleApp());
}

class BigStyleApp extends StatelessWidget {
  const BigStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    final paymentService = PaymentService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: productService),
        RepositoryProvider.value(value: paymentService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(AuthService(), GoogleAuthService()),
          ),
          BlocProvider(create: (_) => ProductBloc(productService)),
          BlocProvider(create: (_) => ProductDetailBloc(productService)),
          BlocProvider(create: (_) => ManagerProductBloc(productService)),
          BlocProvider(
            create: (_) =>
                ManagerCategoryBloc(CategoryService(), productService),
          ),
          BlocProvider(create: (_) => ManagerVoucherBloc(VoucherService())),
          BlocProvider(create: (_) => CartBloc(CartService())),
          BlocProvider(create: (_) => OrderBloc(OrderService())),
          BlocProvider(
            create: (ctx) =>
                CheckoutBloc(OrderService(), CartService(), paymentService),
          ),
          BlocProvider(create: (_) => NotificationBloc(NotificationService())),
          BlocProvider(create: (_) => ChatBloc(ChatService())),
          BlocProvider(create: (_) => ManagerBloc(OrderService())),
          BlocProvider(create: (_) => ReviewBloc(ReviewService())),
          BlocProvider(create: (_) => WishlistBloc(WishlistService())),
          BlocProvider(
            create: (_) => PaymentBloc(paymentService, CartService()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthSuccess &&
              current.user != null &&
              !current.user!.id.startsWith('mock-'),
          listener: (context, state) {
            context.read<CartBloc>().add(CartLoad(state.user!.id));
          },
          child: MaterialApp(
            title: 'BigStyle',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            initialRoute: '/',
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      ),
    );
  }
}
