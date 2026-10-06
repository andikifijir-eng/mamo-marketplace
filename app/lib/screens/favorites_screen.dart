import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(favoritesProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              message: 'Belum ada produk favorit.\nTekan ikon hati di halaman produk.',
              icon: Icons.favorite_border,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoritesProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (c, i) {
                final p = products[i];
                return Stack(children: [
                  ProductCard(
                    name: p.name,
                    price: p.price,
                    imageUrl: p.imageUrl,
                    location: p.location ?? p.categoryName,
                    conditionLabel: p.conditionLabel,
                    onTap: () => context.push('/product/${p.id}'),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await ref.read(productRepoProvider).removeFavorite(p.id);
                        ref.invalidate(favoritesProvider);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle, boxShadow: [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 6),
                          ]),
                        child: const Icon(Icons.favorite,
                            size: 16, color: MamoColors.danger),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          );
        },
      ),
    );
  }
}
