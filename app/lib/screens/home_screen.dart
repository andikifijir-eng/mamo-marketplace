import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Home sesuai desain Figma:
/// header logo + pesan/notifikasi → greeting + tombol profil → search +
/// lokasi → kategori (kotak pastel) → banner gelap "Barang di Sekitarmu" →
/// grid produk dgn ikon hati → bottom nav + tombol tambah produk.
///
/// Semua data tetap dari provider/API yang sama seperti sebelumnya.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Biru aksen khusus Home sesuai desain (#4858E8).
  static const _blue = Color(0xFF4858E8);

  /// Warna kotak ikon kategori, dipakai berulang sesuai urutan kategori.
  static const _catColors = <({Color bg, Color fg})>[
    (bg: Color(0xFFEEF0FF), fg: Color(0xFF4858E8)),
    (bg: Color(0xFFFFF3DD), fg: Color(0xFFD97706)),
    (bg: Color(0xFFF4EDFF), fg: Color(0xFF7C3AED)),
    (bg: Color(0xFFE8F7F1), fg: Color(0xFF0F9D6A)),
    (bg: Color(0xFFFFF0F0), fg: Color(0xFFE24C4C)),
  ];

  /// Produk yang sedang di-favoritkan (optimistic; sumber kebenaran tetap API).
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
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeProductsProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(homeProductsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ───────────── HEADER: logo + pesan + notifikasi
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 34, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 7),
                  const Text('MAMO',
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: MamoColors.textPrimary)),
                  const Spacer(),
                  _headerIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => context.go('/chat'),
                  ),
                  const SizedBox(width: 4),
                  _headerIcon(
                    icon: Icons.notifications_none_rounded,
                    badge: ref.watch(notificationsProvider).valueOrNull?.unread ?? 0,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),

            // ───────────── GREETING + tombol profil
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 30, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, $name',
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 5),
                        const Text('Mau cari apa hari ini?',
                            style: TextStyle(
                                fontSize: 12.5, color: MamoColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8EAFC), width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            // ───────────── SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 34, 21, 0),
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.search, size: 19, color: MamoColors.textMuted),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text('Cari barang di sekitarmu...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: MamoColors.textMuted)),
                    ),
                  ]),
                ),
              ),
            ),

            // ───────────── LOKASI
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 7, 22, 0),
              child: Row(children: const [
                Icon(Icons.location_on_outlined, size: 14, color: _blue),
                SizedBox(width: 4),
                Text('Semarang, Indonesia',
                    style: TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
                Icon(Icons.keyboard_arrow_down,
                    size: 15, color: MamoColors.textSecondary),
              ]),
            ),

            // ───────────── KATEGORI
            const SizedBox(height: 2),
            const SectionHeader(title: 'Kategori'),
            cats.when(
              loading: () => const SizedBox(
                height: 78,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text('Gagal memuat kategori',
                    style: TextStyle(fontSize: 12, color: MamoColors.danger)),
              ),
              data: (list) => SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (c, i) {
                    final cat = list[i];
                    final col = _catColors[i % _catColors.length];
                    return GestureDetector(
                      onTap: () => context.push('/search?category=${cat.id}'),
                      child: SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: col.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_iconFor(cat.name), size: 19, color: col.fg),
                            ),
                            const SizedBox(height: 7),
                            Flexible(
                              child: Text(cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: MamoColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ───────────── BANNER "Barang di Sekitarmu"
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 14, 21, 0),
              child: _NearbyBanner(onTap: () => context.push('/search')),
            ),

            // ───────────── PRODUK LOKAL
            const SizedBox(height: 7),
            const SectionHeader(title: 'Produk Lokal', actionLabel: 'Lihat semua'),
            products.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorState(
                  message: '$e',
                  onRetry: () => ref.invalidate(homeProductsProvider),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      message: 'Belum ada produk di sekitarmu',
                      icon: Icons.storefront_outlined,
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(21, 4, 21, 0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final p = list[i];
                    final fav = _favIds.contains(p.id);
                    return ProductCard(
                      name: p.name,
                      price: p.price,
                      imageUrl: p.imageUrl,
                      location: p.location ?? p.categoryName,
                      conditionLabel: p.conditionLabel,
                      onTap: () => context.push('/product/${p.id}'),
                      trailing: GestureDetector(
                        onTap: () => _toggleFavorite(p),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
                          child: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            size: 17,
                            color: fav ? MamoColors.danger : MamoColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 90), // ruang untuk bottom nav
          ],
        ),
      ),

      // ───────────── TOMBOL TAMBAH PRODUK (tengah, mengambang)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () => context.push('/sell'),
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 26),
        ),
      ),
    );
  }

  /// Ikon header (pesan / notifikasi) di dalam lingkaran lembut.
  Widget _headerIcon({
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F5FE),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 19, color: MamoColors.textPrimary),
            if (badge > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 13),
                  decoration: BoxDecoration(
                    color: MamoColors.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Ikon kategori dipilih dari namanya supaya tidak monoton.
  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('buku') || n.contains('tulis')) return Icons.menu_book_outlined;
    if (n.contains('elektron')) return Icons.devices_other_outlined;
    if (n.contains('fashion')) return Icons.checkroom_outlined;
    if (n.contains('gaming') || n.contains('game')) return Icons.sports_esports_outlined;
    if (n.contains('kos') || n.contains('furniture') || n.contains('perabot')) {
      return Icons.chair_outlined;
    }
    if (n.contains('olahraga') || n.contains('sport')) return Icons.sports_soccer_outlined;
    return Icons.category_outlined;
  }
}

/// Banner gelap "Barang di Sekitarmu" (navy → biru, sesuai desain).
class _NearbyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NearbyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 175,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2440), Color(0xFF2B4C7E)],
          ),
        ),
        child: Stack(
          children: [
            // Glow lembut menggantikan ilustrasi foto pada desain.
            Positioned(
              right: -50,
              top: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_outlined, size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text('DI SEKITARMU',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Barang di Sekitarmu',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                  const SizedBox(height: 6),
                  const Text('Temukan barang terdekat dari kampusmu,\nbisa COD tanpa ongkir.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11.5, height: 1.4)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Lihat sekitar',
                          style: TextStyle(
                              color: Color(0xFF1A2440),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 13, color: Color(0xFF1A2440)),
                    ]),
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
