import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../widgets/common.dart';

/// Bottom navigation: Home, Favorit, Chat, Profil (+ cart badge di AppBar).
class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/favorites')) return 1;
    if (loc.startsWith('/chat')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _index(loc);
    final cartCount = ref.watch(cartProvider).valueOrNull?.items.length ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home'); break;
            case 1: context.go('/favorites'); break;
            case 2: context.go('/chat'); break;
            case 3: context.go('/profile'); break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil'),
        ],
      ),
    );
  }
}

/// Header umum: logo + notifikasi (dengan badge) + keranjang.
class MamoHeader extends ConsumerWidget implements PreferredSizeWidget {
  final bool showLogo;
  const MamoHeader({super.key, this.showLogo = true});

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).valueOrNull?.unread ?? 0;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: showLogo ? const MamoLogo(size: 30) : null,
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        IconButton(
          onPressed: () => context.go('/cart'),
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
