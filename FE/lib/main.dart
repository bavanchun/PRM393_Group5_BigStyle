import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'config/supabase/supabase_config.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/product/product_bloc.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/checkout/checkout_bloc.dart';
import 'blocs/order/order_bloc.dart';
import 'blocs/notification/notification_bloc.dart';
import 'blocs/chat/chat_bloc.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(AuthService(), GoogleAuthService()),
        ),
        BlocProvider(create: (_) => ProductBloc(ProductService())),
        BlocProvider(create: (_) => CartBloc(CartService())),
        BlocProvider(create: (_) => OrderBloc(OrderService())),
        BlocProvider(
          create: (ctx) => CheckoutBloc(
            OrderService(),
            CartService(),
          ),
        ),
        BlocProvider(create: (_) => NotificationBloc(NotificationService())),
        BlocProvider(create: (_) => ChatBloc(ChatService())),
      ],
      child: MaterialApp(
        title: 'BigStyle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
