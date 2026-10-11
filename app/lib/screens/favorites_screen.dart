import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Favorit sesuai desain Figma + 3 fitur baru:
/// 1. Urutkan (Terbaru / Termurah / Termahal / Terpopuler)
/// 2. Pindah ke keranjang (tombol cart di tiap kartu)
/// 3. Notifikasi stok (bell icon untuk barang habis → alert lokal)
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum _SortMode { newest, cheapest, expensive, popular }

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _tabIndex = 0; // 0=Semua, 1=Aktif, 2=Habis
  _SortMode _sort = _SortMode.newest;
  Set<String> _stockAlerts = {}; // product IDs with stock alert on

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mamo_stock_alerts');
    if (raw != null) {
      setState(() {
        _stockAlerts = (jsonDecode(raw) as List).cast<String>().toSet();
      });
    }
  }

  Future<void> _toggleAlert(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_stockAlerts.contains(productId)) {
        _stockAlerts.remove(productId);
      } else {
        _stockAlerts.add(productId);
      }
    });
    await prefs.setString(
        'mamo_stock_alerts', jsonEncode(_stockAlerts.toList()));
  }

  List<Product> _applySort(List<Product> items) {
    final list = List<Product>.from(items);
    switch (_sort) {
      case _SortMode.newest:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
      case _SortMode.cheapest:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _SortMode.expensive:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _SortMode.popular:
        list.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
        break;
    }
    return list;
  }

  String get _sortLabel => switch (_sort) {
        _SortMode.newest => 'Terbaru',
        _SortMode.cheapest => 'Termurah',
        _SortMode.expensive => 'Termahal',
        _SortMode.popular => 'Terpopuler',
      };

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
                  const Spacer(),
                  // ── FITUR 1: Sort button ──────────────────────────
                  GestureDetector(
                    onTap: () => _showSortSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded,
                              size: 16, color: Color(0xFF4858E8)),
                          const SizedBox(width: 4),
                          Text(_sortLabel,
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Color(0xFF4858E8))),
                        ],
                      ),
                    ),
                  ),
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

                  // Apply sort
                  final sorted = _applySort(filtered);

                  if (sorted.isEmpty) {
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
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (c, i) {
                        final p = sorted[i];
                        final isAlertOn = _stockAlerts.contains(p.id);
                        return Stack(
                          children: [
                            ProductCard(
                              name: p.name,
                              price: p.price,
                              imageUrl: p.imageUrl,
                              location: p.location ?? p.categoryName ?? '',
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
                                  if (context.mounted) {
                                    showSnack(context, 'Dihapus dari favorit');
                                  }
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
                            // ── FITUR 2: Add to cart (bottom-right) ───
                            if (p.stock > 0)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () async {
                                    try {
                                      await ref
                                          .read(cartRepoProvider)
                                          .add(p.id);
                                      if (context.mounted) {
                                        showSnack(context,
                                            'Ditambah ke keranjang');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        showSnack(context,
                                            'Gagal: ${ApiClient.errorMessage(e)}');
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4858E8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4858E8)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            // ── FITUR 3: Stock alert bell (bottom-left) ─
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: GestureDetector(
                                onTap: () async {
                                  await _toggleAlert(p.id);
                                  if (context.mounted) {
                                    final msg = _stockAlerts.contains(p.id)
                                        ? (p.stock > 0
                                            ? 'Notifikasi stok aktif'
                                            : 'Kami beri tahu saat barang tersedia lagi')
                                        : 'Notifikasi stok dimatikan';
                                    showSnack(context, msg);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _stockAlerts.contains(p.id)
                                        ? const Color(0xFFEEF0FF)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0x1A000000),
                                          blurRadius: 4),
                                    ],
                                  ),
                                  child: Icon(
                                    isAlertOn
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_none_rounded,
                                    size: 16,
                                    color: isAlertOn
                                        ? const Color(0xFF4858E8)
                                        : const Color(0xFF9CA3AF),
                                  ),
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

  // ── FITUR 1: Sort bottom sheet ──────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Urutkan favorit',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFF0B0B0B))),
              const SizedBox(height: 16),
              ..._SortMode.values.map((mode) {
                final selected = _sort == mode;
                final label = switch (mode) {
                  _SortMode.newest => 'Terbaru',
                  _SortMode.cheapest => 'Termurah',
                  _SortMode.expensive => 'Termahal',
                  _SortMode.popular => 'Terpopuler',
                };
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    switch (mode) {
                      _SortMode.newest => Icons.access_time_rounded,
                      _SortMode.cheapest => Icons.arrow_downward_rounded,
                      _SortMode.expensive => Icons.arrow_upward_rounded,
                      _SortMode.popular => Icons.trending_up_rounded,
                    },
                    size: 20,
                    color: selected
                        ? const Color(0xFF4858E8)
                        : const Color(0xFF9CA3AF),
                  ),
                  title: Text(label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF4858E8)
                            : const Color(0xFF172039))),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded,
                          size: 20, color: Color(0xFF4858E8))
                      : null,
                  onTap: () {
                    setState(() => _sort = mode);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
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
