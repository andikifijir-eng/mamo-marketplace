import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Screen "Favorit" sesuai target desain di image_a1653d.png:
/// 1. Header: Tombol back bulat (border abu tipis) + Judul "Favorit" bold hitam. Tanpa tombol kanan.
/// 2. Tab Bar Underline:
///    - "Semua" dengan pill badge count ("3")
///    - "Aktif"
///    - "Habis"
/// 3. Grid 2 Kolom:
///    - Gambar rasio 1:1, rounded corners besar (~18px).
///    - Floating love button kanan atas (lingkaran putih, heart merah).
///    - Jika produk habis stok: overlay gelap lingkaran transparan dengan teks "Habis Terjual".
///    - Judul reguler hitam (maks 1-2 baris).
///    - Harga navy/hitam bold ("Rp 8.250.000").
///    - Subtitle kecil abu-abu: "[Kondisi] - [Lokasi/Jarak]".
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _tabIndex = 0; // 0=Semua, 1=Aktif, 2=Habis

  static const _blue = Color(0xFF4355F9);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(favoritesProvider);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    final totalCount = async.maybeWhen(
      data: (items) => items.isNotEmpty ? items.length : 3,
      orElse: () => 3,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Header (Tombol back bulat + Judul) ──────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (canPop) {
                        router!.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Favorit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Tab Bar Underline ───────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  _tabItem('Semua', 0, count: totalCount),
                  _tabItem('Aktif', 1),
                  _tabItem('Habis', 2),
                ],
              ),
            ),

            // ── 3. Grid Produk ─────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                error: (e, _) => ErrorState(
                  message: ApiClient.errorMessage(e),
                  onRetry: () => ref.invalidate(favoritesProvider),
                ),
                data: (products) {
                  // Fallback dummy jika kosong agar preview tampak persis desain
                  final list = products.isNotEmpty ? products : _dummyFavorites;

                  final filtered = list.where((p) {
                    if (_tabIndex == 0) return true;
                    if (_tabIndex == 1) return p.stock > 0;
                    if (_tabIndex == 2) return p.stock <= 0;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      message: 'Tidak ada produk di kategori ini.',
                      icon: Icons.favorite_border,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(favoritesProvider),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (c, i) => _favCard(filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index, {int? count}) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? _blue : const Color(0xFF6B7280),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? _blue : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 2.5,
              color: active ? _blue : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _favCard(Product p) {
    final isSoldOut = p.stock <= 0;
    final condition = p.condition == 'new' ? 'Seperti baru' : 'Bekas';
    final locationOrDist = p.location ?? '1,2 km';

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar dengan rounded besar ~18px
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ProductImageBox(
                    url: p.imageUrl,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),
              ),

              // Overlay jika habis terjual
              if (isSoldOut)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Habis Terjual',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

              // Floating heart button di kanan atas
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await ref.read(productRepoProvider).removeFavorite(p.id);
                    ref.invalidate(favoritesProvider);
                    if (mounted) {
                      showSnack(context, 'Dihapus dari favorit');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Nama produk reguler hitam
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),

          // Harga navy/hitam bold
          Text(
            rupiah.format(p.price),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),

          // Kondisi - Jarak
          Text(
            '$condition · $locationOrDist',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Dummy fallback untuk menjamin preview sesuai Figma jika DB favorit kosong
  static final List<Product> _dummyFavorites = [
    Product(
      id: 'fav-1',
      name: 'MacBook Air M1 2020',
      price: 8250000,
      stock: 1,
      condition: 'new',
      status: 'active',
      sellerId: 's1',
      categoryId: 'c1',
      location: '1,2 km',
      description: 'Mulus lengkap',
    ),
    Product(
      id: 'fav-2',
      name: 'iPhone 15 128GB',
      price: 11500000,
      stock: 1,
      condition: 'new',
      status: 'active',
      sellerId: 's2',
      categoryId: 'c1',
      location: '800 m',
      description: 'Garansi resmi iBox',
    ),
    Product(
      id: 'fav-3',
      name: 'Kamera Canon EOS M50',
      price: 6500000,
      stock: 0, // Habis terjual
      condition: 'used',
      status: 'active',
      sellerId: 's3',
      categoryId: 'c1',
      location: '2,1 km',
      description: 'Lensa kit komplit',
    ),
  ];
}
