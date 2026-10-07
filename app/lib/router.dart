import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_shell.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/seller_dashboard_screen.dart';
import '../screens/seller_products_screen.dart';
import '../screens/seller_orders_screen.dart';
import '../screens/sell_product_screen.dart';
import '../models/models.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Router dibuat SEKALI saja — kalau dibuat ulang setiap rebuild,
/// GoRouter ter-reset ke initialLocation dan app nyangkut di splash.
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final publicRoutes = ['/splash', '/onboarding', '/login', '/register'];
      if (auth.initializing) return loc == '/splash' ? null : '/splash';
      if (!auth.loggedIn && !publicRoutes.contains(loc)) return '/login';
      // /onboarding boleh diakses saat sudah login: onboarding post-login
      if (auth.loggedIn && publicRoutes.contains(loc) &&
          loc != '/splash' && loc != '/onboarding') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      ShellRoute(
        builder: (c, s, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/favorites', builder: (c, s) => const FavoritesScreen()),
          GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
          GoRoute(path: '/chat', builder: (c, s) => const ChatListScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/search', builder: (c, s) =>
          SearchScreen(initialCategoryId: s.uri.queryParameters['category'])),
      GoRoute(path: '/product/:id', builder: (c, s) =>
          ProductDetailScreen(productId: s.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (c, s) => const OrdersScreen()),
      GoRoute(path: '/order/:id', builder: (c, s) =>
          OrderDetailScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/chat/:id', builder: (c, s) =>
          ChatScreen(conversationId: s.pathParameters['id']!, otherName: s.extra as String?)),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/verification', builder: (c, s) => const VerificationScreen()),
      GoRoute(path: '/sell', builder: (c, s) => const SellProductScreen(product: null)),
      GoRoute(path: '/sell/:id', builder: (c, s) =>
          SellProductScreen(product: s.extra as Product?)),
      GoRoute(path: '/seller', builder: (c, s) => const SellerDashboardScreen()),
      GoRoute(path: '/seller/products', builder: (c, s) => const SellerProductsScreen()),
      GoRoute(path: '/seller/orders', builder: (c, s) => const SellerOrdersScreen()),
    ],
  );
}

/// Bridge agar GoRouter rebuild saat auth berubah.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
