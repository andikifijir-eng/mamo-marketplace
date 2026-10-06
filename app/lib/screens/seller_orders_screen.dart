import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

final sellerOrdersProvider = FutureProvider.autoDispose<List<Order>>(
    (ref) => ref.read(orderRepoProvider).list(asSeller: true));

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Masuk')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(sellerOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              message: 'Belum ada pesanan masuk',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (c, i) {
                final o = orders[i];
                final first = o.items.isNotEmpty ? o.items.first : null;
                return InkWell(
                  onTap: () => context.push('/order/${o.id}'),
                  borderRadius: BorderRadius.circular(MamoRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(MamoRadius.lg),
                      border: Border.all(color: MamoColors.cardBorder),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${o.shortId}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: MamoColors.textSecondary)),
                          StatusPill.order(o.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        ProductImageBox(url: first?.productImage, height: 54, width: 54),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(first?.productName ?? 'Produk',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('Pembeli: ${o.buyerName ?? '-'}',
                                  style: const TextStyle(
                                      fontSize: 11, color: MamoColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(rupiah.format(o.totalAmount),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: MamoColors.primary)),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
