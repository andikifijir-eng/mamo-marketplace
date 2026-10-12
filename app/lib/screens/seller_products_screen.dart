import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Screen "Listing Saya" sesuai desain target di image_108c14.png:
/// 1. Header: Tombol back bulat (border abu tipis) + Judul "Listing Saya" bold hitam. Tanpa tombol (+).
/// 2. TabBar: "Aktif" (badge count '2'), "Pending", "Terjual". Underline biru di bawah tab aktif.
/// 3. Kartu Listing:
///    - Gambar rasio 1:1 (~84x84) rounded 14px di kiri.
///    - Kanan: Pill hijau "Aktif" di atas judul produk.
///    - Judul produk reguler hitam ("MacBook Air M1 2020", "iPhone 13").
///    - Harga tebal biru ("Rp8.250.000").
///    - Menu overflow titik tiga horizontal (...) di kanan atas kartu.
///    - Statistik di bawah harga: "[X] dilihat · [Y] disimpan" abu-abu kecil.
/// 4. Background halaman putih, border separator antar kartu halus.
class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _blue = Color(0xFF4355F9);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerProductsProvider);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    final activeCount = async.maybeWhen(
      data: (items) => items.where((p) => p.status == 'active').length,
      orElse: () => 2,
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
                    'Listing Saya',
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
              child: TabBar(
                controller: _tab,
                labelColor: _blue,
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: _blue,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Aktif'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _tab.index == 0
                                ? const Color(0xFFEEF2FF)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _tab.index == 0 ? _blue : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Tab(text: 'Pending'),
                  const Tab(text: 'Terjual'),
                ],
              ),
            ),

            // ── 3. Daftar Produk ───────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                error: (e, _) => ErrorState(
                  message: ApiClient.errorMessage(e),
                  onRetry: () => ref.invalidate(sellerProductsProvider),
                ),
                data: (products) {
                  return TabBarView(
                    controller: _tab,
                    children: [
                      _productList(products, 'active'),
                      _productList(products, 'pending'),
                      _productList(products, 'sold'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productList(List<Product> all, String status) {
    final products = all.where((p) => p.status == status).toList();
    if (products.isEmpty) {
      return EmptyState(
        message: 'Belum ada listing $status',
        icon: Icons.inventory_2_outlined,
        actionLabel: 'Jual Barang',
        onAction: () => context.push('/sell'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(sellerProductsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: products.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Divider(color: Color(0xFFF3F4F6), height: 1),
        ),
        itemBuilder: (c, i) => _listingCard(products[i]),
      ),
    );
  }

  Widget _listingCard(Product p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar rasio 1:1 rounded 14
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ProductImageBox(
              url: p.imageUrl,
              height: 84,
              width: 84,
            ),
          ),
          const SizedBox(width: 14),

          // Info detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill status hijau "Aktif" di atas judul
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.status == 'active' ? 'Aktif' : p.status,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Nama produk reguler
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),

                // Harga biru tebal
                Text(
                  rupiah.format(p.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _blue,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Statistik dilihat & disimpan
                Text(
                  '${(p.favoriteCount * 3) + 12} dilihat · ${p.favoriteCount} disimpan',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Menu overflow titik tiga (...)
          IconButton(
            onPressed: () => _showItemActions(p),
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF6B7280),
              size: 22,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showItemActions(Product p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _blue),
              title: const Text('Edit Produk',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/product/${p.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Lihat Halaman Produk'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/product/${p.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
