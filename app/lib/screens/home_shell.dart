import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../widgets/common.dart';

/// Bottom navigation bar MAMO sesuai desain Figma:
/// Bar putih dengan sudut atas melengkung, 2 tab utama (Home & Profile),
/// serta tombol floating '+' di tengah untuk tambah/jual produk.
class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _blue = Color(0xFF4858E8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String loc = '/home';
    try {
      loc = GoRouterState.of(context).matchedLocation;
    } catch (_) {}
    final isHome = loc == '/home';
    final isListing = loc.startsWith('/seller/products');
    final isProfile = loc.startsWith('/profile');

    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      // FAB (+) mengambang di pojok kanan bawah seperti tombol chat WhatsApp
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sell'),
        backgroundColor: _blue,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                // 1. Tab Home
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/home'),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isHome ? Icons.home_rounded : Icons.home_outlined,
                          size: 24,
                          color: isHome ? _blue : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isHome ? FontWeight.w700 : FontWeight.w500,
                            color: isHome ? _blue : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Tab Listing Saya (Ikon Etalase di Tengah)
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/seller/products'),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isListing ? Icons.storefront_rounded : Icons.storefront_outlined,
                          size: 24,
                          color: isListing ? _blue : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Listing Saya',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isListing ? FontWeight.w700 : FontWeight.w500,
                            color: isListing ? _blue : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Tab Profile
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/profile'),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isProfile ? Icons.person_rounded : Icons.person_outline_rounded,
                          size: 24,
                          color: isProfile ? _blue : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isProfile ? FontWeight.w700 : FontWeight.w500,
                            color: isProfile ? _blue : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header umum bila dipakai di sub-halaman: logo + notifikasi + keranjang.
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
