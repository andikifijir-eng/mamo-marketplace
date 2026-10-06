import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

final sellerProductsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.read(sellerRepoProvider).products());

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Saya'),
        actions: [
          IconButton(
            onPressed: () => context.push('/sell'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(sellerProductsProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              message: 'Kamu belum punya listing',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Jual Barang',
              onAction: () => context.push('/sell'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerProductsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (c, i) {
                final p = products[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(MamoRadius.lg),
                    border: Border.all(color: MamoColors.cardBorder),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ProductImageBox(url: p.imageUrl, height: 72, width: 72),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(rupiah.format(p.price),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MamoColors.primary)),
                        const SizedBox(height: 6),
                        Row(children: [
                          StatusPill.order(p.status),
                          const Spacer(),
                          Text('stok ${p.stock}',
                              style: const TextStyle(
                                  fontSize: 11, color: MamoColors.textSecondary)),
                        ]),
                      ]),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          context.push('/sell/${p.id}', extra: p);
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Hapus Listing?'),
                              content: Text('"${p.name}" akan diarsipkan.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Batal')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: MamoColors.danger),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            try {
                              await ref.read(productRepoProvider).delete(p.id);
                              ref.invalidate(sellerProductsProvider);
                              if (context.mounted) showSnack(context, 'Listing diarsipkan');
                            } catch (e) {
                              if (context.mounted) {
                                showSnack(context, ApiClient.errorMessage(e), error: true);
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (c) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
