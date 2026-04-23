import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/inventory/parts_list_screen.dart';
import 'screens/billing/billing_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/delivery/delivery_list_screen.dart';
import 'screens/home_router.dart';
import 'screens/orders/my_orders_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Prepare async initialization (Firebase + Supabase) with proper env handling.
    final initFuture = _initializeServices();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: FutureBuilder<void>(
        future: initFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          if (snap.hasError) {
            // Show an actionable error screen instead of a blank screen/crash.
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: _InitErrorScreen(error: snap.error!),
            );
          }
          return Consumer<AuthService>(
            builder: (context, auth, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Vehicle Parts Inventory',
                theme: AppTheme.darkTheme,
                home: auth.initializing
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      )
                    : (auth.isLoggedIn ? const HomeRouter() : const LoginScreen()),
                routes: {
                  PartsListScreen.routeName: (_) => const PartsListScreen(),
                  LoginScreen.routeName: (_) => const LoginScreen(),
                  BillingScreen.routeName: (_) => const BillingScreen(),
                  ReportsScreen.routeName: (_) => const ReportsScreen(),
                  DeliveryListScreen.routeName: (_) => const DeliveryListScreen(),
                  MyOrdersScreen.routeName: (_) => const MyOrdersScreen(),
                  CartScreen.routeName: (_) => const CartScreen(),
                  '/payment-method': (context) => PaymentMethodScreen(
                    total: ModalRoute.of(context)!.settings.arguments as double? ?? 0.0,
                  ),
                  '/checkout': (context) => const CheckoutScreen(),
                  OrderSuccessScreen.routeName: (context) {
                    final args = ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>?;
                    return OrderSuccessScreen(
                      orderId: args?['orderId'] ?? '',
                      total: args?['total'] ?? 0.0,
                      paymentMethod: args?['paymentMethod'],
                    );
                  },
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Initialize Firebase and Supabase with proper env variable names.
Future<void> _initializeServices() async {
  await Firebase.initializeApp(); // Ensure platform configs (google-services/GoogleService-Info.plist) exist.
  // Hardcoded Supabase configuration provided by user.
  const supabaseUrl = 'https://djzxpkuyaoohlcfeqxhe.supabase.co';
  const supabaseAnonKey = 'sb_publishable_Vap_7U7vKeWy4E_YIcWm4A_NWLiokJ5';
  await SupabaseService.init(url: supabaseUrl, anonKey: supabaseAnonKey);
}

class _InitErrorScreen extends StatelessWidget {
  final Object error;
  const _InitErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initialization Error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The app failed to initialize required services.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            const Text('Tip:'),
            const Text(
              'Run with: --dart-define=supabaseUrl=YOUR_URL --dart-define=supabaseAnonKey=YOUR_KEY',
            ),
          ],
        ),
      ),
    );
  }
}
