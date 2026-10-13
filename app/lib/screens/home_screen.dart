import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Halaman Home MAMO sesuai referensi desain Figma:
/// 1. Header: Logo MAMO (mark custom + text) & icon Chat + Notifikasi (lingkaran putih + red dot)
/// 2. Greeting: "SELAMAT DATANG", "Halo, Nama!", subtitle, dan squircle profile button
/// 3. Search Bar: background abu lembut + tombol "Cari" di dalam bar
/// 4. Lokasi: "Menampilkan area sekitar Universitas Diponegoro"
/// 5. Kategori: "Jelajahi Kategori" & "Lihat semua" + kotak pastel & ikon
/// 6. Banner "DEKAT DENGANMU": foto kampus di kanan + dark navy gradient + button
/// 7. "PILIHAN LOKAL": "Barang di sekitarmu" & "Lihat semua"
/// 8. Kartu Produk: gambar rounded besar, floating favorite button di pojok kanan atas foto
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Biru aksen Figma MAMO (#4858E8).
  static const _blue = Color(0xFF4858E8);

  /// Warna kotak ikon kategori pastel sesuai urutan.
  static const _catStyles = [
    (bg: Color(0xFFEEF2FF), fg: Color(0xFF4858E8), icon: Icons.menu_book_rounded),
    (bg: Color(0xFFFEF3C7), fg: Color(0xFFD97706), icon: Icons.laptop_chromebook_rounded),
    (bg: Color(0xFFF3E8FF), fg: Color(0xFF9333EA), icon: Icons.checkroom_rounded),
    (bg: Color(0xFFECFDF5), fg: Color(0xFF059669), icon: Icons.home_outlined),
    (bg: Color(0xFFFFE4E6), fg: Color(0xFFE11D48), icon: Icons.sports_esports_outlined),
    (bg: Color(0xFFF1F5F9), fg: Color(0xFF64748B), icon: Icons.more_horiz_rounded),
  ];

  static final List<Category> _defaultCategories = [
    Category(id: 'cat-1', name: 'Buku', icon: 'book'),
    Category(id: 'cat-2', name: 'Elektronik', icon: 'laptop'),
    Category(id: 'cat-3', name: 'Fashion', icon: 'shirt'),
    Category(id: 'cat-4', name: 'Kos', icon: 'home'),
    Category(id: 'cat-5', name: 'Gaming', icon: 'gamepad'),
    Category(id: 'cat-6', name: 'Lainnya', icon: 'more'),
  ];

  static final List<Product> _fallbackProducts = [
    Product(
      id: 'prod-1',
      name: 'Buku Kalkulus Purcell Edisi 9',
      price: 85000,
      stock: 1,
      condition: 'used',
      status: 'active',
      location: 'Tembalang, Semarang',
      sellerId: 'user-1',
      sellerName: 'Budi Santoso',
      images: [
        ProductImage(
          id: 'img-1',
          imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500&q=80',
        ),
      ],
    ),
    Product(
      id: 'prod-2',
      name: 'Logitech G102 Lightsync Mouse Gaming',
      price: 175000,
      stock: 1,
      condition: 'used',
      status: 'active',
      location: 'Banyumanik, Semarang',
      sellerId: 'user-2',
      sellerName: 'Reza Pratama',
      images: [
        ProductImage(
          id: 'img-2',
          imageUrl: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=500&q=80',
        ),
      ],
    ),
    Product(
      id: 'prod-3',
      name: 'Jaket Hoodie Uniqlo Abu-Abu Size L',
      price: 120000,
      stock: 1,
      condition: 'used',
      status: 'active',
      location: 'Tembalang, Semarang',
      sellerId: 'user-3',
      sellerName: 'Dinda Ayu',
      images: [
        ProductImage(
          id: 'img-3',
          imageUrl: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=500&q=80',
        ),
      ],
    ),
    Product(
      id: 'prod-4',
      name: 'Keyboard Mechanical Keychron K2 V2',
      price: 650000,
      stock: 1,
      condition: 'used',
      status: 'active',
      location: 'Pleburan, Semarang',
      sellerId: 'user-4',
      sellerName: 'Fajar Nugroho',
      images: [
        ProductImage(
          id: 'img-4',
          imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500&q=80',
        ),
      ],
    ),
  ];

  final Set<String> _favBusy = {};
  final Set<String> _favIds = {};

  Future<void> _toggleFavorite(Product p) async {
    if (_favBusy.contains(p.id)) return;
    final wasFav = _favIds.contains(p.id);
    setState(() {
      _favBusy.add(p.id);
      wasFav ? _favIds.remove(p.id) : _favIds.add(p.id);
    });
    try {
      final repo = ref.read(productRepoProvider);
      wasFav ? await repo.removeFavorite(p.id) : await repo.addFavorite(p.id);
      ref.invalidate(favoritesProvider);
    } catch (e) {
      if (mounted) {
        setState(() => wasFav ? _favIds.add(p.id) : _favIds.remove(p.id));
        showSnack(context, 'Gagal mengubah favorit', error: true);
      }
    } finally {
      if (mounted) setState(() => _favBusy.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cats = ref.watch(categoriesProvider);
    final products = ref.watch(homeProductsProvider);
    final user = auth.user;
    final name = user?.displayName ?? 'Mahasiswa';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeProductsProvider);
            ref.invalidate(categoriesProvider);
            await ref.read(homeProductsProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ───────────── 1. HEADER: Logo MAMO & Chat / Notifikasi
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // MAMO Logo Mark & Wordmark
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomPaint(
                        painter: _MamoMarkPainter(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MAMO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),

                    // Chat Button
                    _headerIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      hasDot: true,
                      onTap: () => context.go('/chat'),
                    ),
                    const SizedBox(width: 10),

                    // Notification Button
                    _headerIconButton(
                      icon: Icons.notifications_none_rounded,
                      hasDot: (ref.watch(notificationsProvider).valueOrNull?.unread ?? 0) > 0,
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),

              // ───────────── 2. GREETING & TOMBOL PROFIL
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELAMAT DATANG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Halo, $name!',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Temukan barang bagus dari pengguna di sekitarmu.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ───────────── 3. SEARCH BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Cari Barang yang kamu butuhkan...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Cari',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ───────────── 4. INFORMASI LOKASI
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Menampilkan area sekitar ',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                          children: [
                            TextSpan(
                              text: 'Universitas Diponegoro',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ───────────── 5. JELAJAHI KATEGORI
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jelajahi Kategori',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/search'),
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              cats.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => _buildCategoryList(_defaultCategories),
                data: (list) => _buildCategoryList(list.isNotEmpty ? list : _defaultCategories),
              ),

              // ───────────── 6. BANNER "DEKAT DENGANMU"
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _NearbyBanner(onTap: () => context.push('/search')),
              ),

              // ───────────── 7. PILIHAN LOKAL & BARANG DI SEKITARMU
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PILIHAN LOKAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Barang di sekitarmu',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/search'),
                          child: const Text(
                            'Lihat semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ───────────── 8. KARTU PRODUK
              products.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                ),
                error: (e, _) => _buildProductGrid(_fallbackProducts),
                data: (list) => _buildProductGrid(list.isNotEmpty ? list : _fallbackProducts),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> list) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (c, i) {
          final cat = list[i];
          final style = _styleForCategory(cat.name, i);
          return GestureDetector(
            onTap: () => context.push('/search?category=${cat.id}'),
            child: SizedBox(
              width: 54,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, size: 22, color: style.fg),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name.split(' ')[0],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> list) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (c, i) {
        final p = list[i];
        final isFav = _favIds.contains(p.id);
        return _HomeProductCard(
          product: p,
          isFavorite: isFav,
          onToggleFavorite: () => _toggleFavorite(p),
          onTap: () => context.push('/product/${p.id}'),
        );
      },
    );
  }

  /// Tombol icon bulat di header (Chat & Notifikasi) dengan border halus dan red-dot
  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF4B5563)),
            if (hasDot)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Penentu style warna pastel & icon kategori
  ({Color bg, Color fg, IconData icon}) _styleForCategory(String name, int index) {
    final n = name.toLowerCase();
    if (n.contains('buku') || n.contains('tulis')) return _catStyles[0];
    if (n.contains('elektron') || n.contains('laptop')) return _catStyles[1];
    if (n.contains('fashion') || n.contains('baju')) return _catStyles[2];
    if (n.contains('kos') || n.contains('perabot')) return _catStyles[3];
    if (n.contains('game') || n.contains('gaming')) return _catStyles[4];
    return _catStyles[index % _catStyles.length];
  }
}

/// Custom painter untuk logo mark MAMO (simbol centang / lipatan M putih)
class _MamoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Bentuk kurva lipatan M lembut
    path.moveTo(size.width * 0.28, size.height * 0.40);
    path.lineTo(size.width * 0.50, size.height * 0.65);
    path.lineTo(size.width * 0.72, size.height * 0.38);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Banner "DEKAT DENGANMU" dengan pemandangan kampus di kanan & teks di kiri
class _NearbyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NearbyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 186,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF131D38),
              Color(0xFF1A2A4E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Gambar latar pemandangan kampus di sisi kanan dengan transisi lembut
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 210,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.45],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=600&auto=format&fit=crop&q=80',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF1B2C56),
                    alignment: Alignment.center,
                    child: const Icon(Icons.school_rounded, color: Colors.white24, size: 48),
                  ),
                ),
              ),
            ),

            // Konten teks & tombol di sisi kiri
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEKAT DENGANMU',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Temukan barang di\nsekitarmu.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Belanja lebih dekat, praktis, dan\nhemat ongkir.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat barang terdekat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu produk Home dengan gambar rounded besar & floating wishlist button
class _HomeProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _HomeProductCard({
    required this.product,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar produk dengan floating heart button di pojok kanan atas
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 146,
                  width: double.infinity,
                  child: ProductImageBox(
                    url: product.imageUrl,
                    height: double.infinity,
                    width: double.infinity,
                    radius: 18,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Floating Wishlist Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Judul Produk
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 3),

          // Harga Produk
          Text(
            rupiah.format(product.price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),

          // Lokasi bila ada
          if (product.location != null && product.location!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 11,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    product.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
