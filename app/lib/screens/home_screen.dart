import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// Home sesuai Figma: greeting + search + lokasi + kategori + barang sekitar + rekomendasi.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final cats = ref.watch(categoriesProvider);
    final products = ref.watch(homeProductsProvider);
    final name = auth.user?.displayName ?? 'Mahasiswa';

    return Scaffold(
      appBar: const MamoHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeProductsProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(homeProductsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Greeting + lokasi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: MamoColors.primary),
                    const SizedBox(width: 3),
                    const Text('Semarang, Indonesia',
                        style: TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 16, color: MamoColors.textSecondary),
                  ]),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: MamoColors.surface,
                    borderRadius: BorderRadius.circular(MamoRadius.pill),
                    border: Border.all(color: MamoColors.cardBorder),
                  ),
                  child: const Row(children: [
                    Icon(Icons.search, size: 20, color: MamoColors.textMuted),
                    SizedBox(width: 8),
                    Text('Cari barang di sekitarmu...',
                        style: TextStyle(fontSize: 13, color: MamoColors.textMuted)),
                  ]),
                ),
              ),
            ),

            // Kategori
            const SectionHeader(title: 'Kategori'),
            cats.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 78,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Gagal memuat kategori',
                    style: TextStyle(fontSize: 12, color: MamoColors.danger)),
              ),
              data: (list) => SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (c, i) {
                    final cat = list[i];
                    return GestureDetector(
                      onTap: () => context.push('/search?category=${cat.id}'),
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: MamoColors.infoBg,
                              borderRadius: BorderRadius.circular(MamoRadius.lg),
                            ),
                            child: const Icon(Icons.category_outlined,
                                size: 24, color: MamoColors.primary),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 66,
                            child: Text(cat.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10, color: MamoColors.textSecondary, height: 1.2)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Barang sekitar
            SectionHeader(
              title: 'Barang di Sekitarmu',
              actionLabel: 'Lihat semua',
              onAction: () => context.push('/search'),
            ),

            // Rekomendasi (semua produk dari API)
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (c, i) {
                    final p = list[i];
                    return ProductCard(
                      name: p.name,
                      price: p.price,
                      imageUrl: p.imageUrl,
                      location: p.location ?? p.categoryName,
                      conditionLabel: p.conditionLabel,
                      onTap: () => context.push('/product/${p.id}'),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
