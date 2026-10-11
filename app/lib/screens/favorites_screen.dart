import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Favorit sesuai desain Figma:
/// Header back bulat + title
/// Tab filter: Semua, Aktif, Habis
/// Grid 2 kolom dengan badge status (Aktif/Habis/Terjual)
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _tabIndex = 0; // 0=Semua, 1=Aktif, 2=Habis

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(favoritesProvider);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBEC2C8)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Color(0xFF0B0B0B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Favorit',
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF0B0B0B))),
                ],
              ),
            ),
            // ── Tabs: Semua, Aktif, Habis ──────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _tabChip('Semua', 0),
                  const SizedBox(width: 8),
                  _tabChip('Aktif', 1),
                  const SizedBox(width: 8),
                  _tabChip('Habis', 2),
                ],
              ),
            ),
            // ── Grid ───────────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5)),
                error: (e, _) => ErrorState(
                  message: ApiClient.errorMessage(e),
                  onRetry: () => ref.invalidate(favoritesProvider),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const EmptyState(
                      message:
                          'Belum ada produk favorit.\nTekan ikon hati di halaman produk.',
                      icon: Icons.favorite_border,
                    );
                  }

                  // Filter by tab
                  final filtered = products.where((p) {
                    if (_tabIndex == 0) return true; // Semua
                    if (_tabIndex == 1) return p.stock > 0; // Aktif
                    if (_tabIndex == 2) return p.stock <= 0; // Habis
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      message: 'Tidak ada produk di kategori ini.',
                      icon: Icons.inbox_outlined,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(favoritesProvider),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (c, i) {
                        final p = filtered[i];
                        return Stack(
                          children: [
                            ProductCard(
                              name: p.name,
                              price: p.price,
                              imageUrl: p.imageUrl,
                              location: p.location ?? p.categoryName,
                              conditionLabel: p.conditionLabel,
                              onTap: () => context.push('/product/${p.id}'),
                            ),
                            // Status badge top-left
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.stock > 0
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.stock > 0 ? 'Aktif' : 'Habis',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: p.stock > 0
                                        ? const Color(0xFF168A61)
                                        : const Color(0xFFD3454D),
                                  ),
                                ),
                              ),
                            ),
                            // Remove favorite button top-right
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () async {
                                  await ref
                                      .read(productRepoProvider)
                                      .removeFavorite(p.id);
                                  ref.invalidate(favoritesProvider);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 6),
                                    ],
                                  ),
                                  child: const Icon(Icons.favorite,
                                      size: 16, color: MamoColors.danger),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _tabChip(String label, int index) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4858E8) : const Color(0xFFF2F3F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
