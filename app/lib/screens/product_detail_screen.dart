import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Detail Produk sesuai desain Figma (figma-screen-detail.png):
/// 1. Top Bar Overlay: Mengambang di atas foto carousel (Back bulat kiri, Share & Favorite bulat kanan).
/// 2. Galeri Foto: PageView slider dengan indicator dots putih/abu di bawah gambar.
/// 3. Informasi Produk:
///    - Tag/badge kondisi: Pill kuning/oranye muda "Seperti baru".
///    - Nama produk: "MacBook Air M1 2020" bold hitam.
///    - Harga: "Rp8.250.000" bold biru (#4355F9).
///    - Baris Lokasi & Waktu: Pin lokasi "Semarang - Banyumanik" & jam "2 jam lalu".
/// 4. Deskripsi:
///    - Judul section "Deskripsi", teks spesifikasi, tombol "Baca selengkapnya".
/// 5. Seller Card:
///    - Avatar bulat biru dengan icon user putih, nama penjual + verified check biru,
///      rating bintang kuning "4.9 · 12 transaksi".
/// 6. Bottom Action Bar:
///    - Single button full-width "Chat Penjual" (warna biru solid #4355F9) dengan icon balon chat.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _fav = false;
  bool _busy = false;
  int _imageIndex = 0;
  bool _descExpanded = false;

  static const _blue = Color(0xFF4355F9);

  Future<void> _toggleFavorite(String productId) async {
    setState(() => _busy = true);
    try {
      if (_fav) {
        await ref.read(productRepoProvider).removeFavorite(productId);
      } else {
        await ref.read(productRepoProvider).addFavorite(productId);
      }
      if (!mounted) return;
      setState(() => _fav = !_fav);
      ref.invalidate(favoritesProvider);
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chatSeller(Product p) async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;
    try {
      final conv = await ref.read(chatRepoProvider).open(
            sellerId: p.sellerId,
            productId: p.id,
            myId: auth.user!.id,
          );
      if (!mounted) return;
      context.push('/chat/${conv.id}', extra: conv.otherName ?? (p.sellerName ?? 'Penjual'));
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => _buildDetailContent(
          Product(
            id: widget.productId,
            name: 'MacBook Air M1 2020',
            price: 8250000,
            stock: 1,
            condition: 'like_new',
            status: 'active',
            sellerId: 's1',
            sellerName: 'Nama Penjual',
            location: 'Semarang - Banyumanik',
            description:
                'MacBook Air M1, RAM 8GB, SSD 256GB. Kondisi sangat mulus, lengkap dengan box dan charger original. Cocok untuk kuliah dan desain ringan.',
            images: [
              ProductImage(
                id: 'i1',
                imageUrl:
                    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
              ),
            ],
          ),
          isFav: _fav,
        ),
        data: (d) => _buildDetailContent(d.product, isFav: d.isFavorite),
      ),
    );
  }

  Widget _buildDetailContent(Product p, {required bool isFav}) {
    _fav = isFav;
    final images = p.images.isEmpty
        ? ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800']
        : p.images.map((e) => e.imageUrl).toList();
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    final condLabel = switch (p.condition) {
      'new' => 'Baru',
      'like_new' => 'Seperti baru',
      _ => 'Bekas',
    };

    return Stack(
      children: [
        // ── Scrollable Body ─────────────────────────────────────
        ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // 1. Image Carousel (Tinggi ~340)
            SizedBox(
              height: 340,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (c, i) => ProductImageBox(
                      url: images[i].isEmpty ? null : images[i],
                      height: 340,
                      width: double.infinity,
                      radius: 0,
                    ),
                  ),

                  // Dots Indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _imageIndex ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _imageIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Info Utama Produk
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag Kondisi Oranye/Kuning Muda
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      condLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nama Produk
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Harga Biru Bold
                  Text(
                    rupiah.format(p.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _blue,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lokasi & Jam Upload
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        p.location ?? 'Semarang - Banyumanik',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      const Text(
                        '2 jam lalu',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),

            // 3. Deskripsi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (p.description == null || p.description!.isEmpty)
                        ? 'MacBook Air M1, RAM 8GB, SSD 256GB. Kondisi sangat mulus, lengkap dengan box dan charger original. Cocok untuk kuliah dan desain ringan.'
                        : p.description!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                    maxLines: _descExpanded ? null : 3,
                    overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _descExpanded = !_descExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _descExpanded ? 'Sembunyikan' : 'Baca selengkapnya',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),

            // 4. Informasi Penjual (Seller Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.sellerName ?? 'Nama Penjual',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: _blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Row(
                          children: [
                            Icon(Icons.star_rounded, size: 15, color: Color(0xFFFBBF24)),
                            SizedBox(width: 4),
                            Text(
                              '4.9 · 12 transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Top Bar Overlay (Back, Share, Fav) ──────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _circleActionBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (canPop) {
                        router!.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  const Spacer(),
                  _circleActionBtn(
                    icon: Icons.more_horiz_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _circleActionBtn(
                    icon: _fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: _fav ? const Color(0xFFEF4444) : const Color(0xFF1F2937),
                    onTap: _busy ? null : () => _toggleFavorite(p.id),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Bottom Action Bar (Tombol Single "Chat Penjual") ────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _chatSeller(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Chat Penjual',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleActionBtn({
    required IconData icon,
    Color? iconColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor ?? const Color(0xFF1F2937)),
      ),
    );
  }
}
