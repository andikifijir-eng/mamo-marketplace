import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Pesanan saya (buyer) & pesanan masuk (seller).
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, this.asSeller = false});

  final bool asSeller;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ordersProvider(widget.asSeller));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asSeller ? 'Pesanan Masuk' : 'Pesanan Saya'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(ordersProvider(widget.asSeller)),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              message: widget.asSeller
                  ? 'Belum ada pesanan masuk'
                  : 'Kamu belum punya pesanan',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider(widget.asSeller)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (c, i) => _OrderCard(order: orders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    final first = order.items.isNotEmpty ? order.items.first : null;
    final moreCount = order.items.length - 1;

    return InkWell(
      onTap: () => context.push('/order/${order.id}'),
      borderRadius: BorderRadius.circular(MamoRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MamoRadius.lg),
          border: Border.all(color: MamoColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.shortId}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: MamoColors.textSecondary)),
                StatusPill.order(order.status),
              ],
            ),
            const SizedBox(height: 10),
            if (first != null)
              Row(children: [
                ProductImageBox(url: first.productImage, height: 56, width: 56),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(first.productName ?? 'Produk',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (moreCount > 0)
                      Text('+$moreCount produk lain',
                          style: const TextStyle(
                              fontSize: 11, color: MamoColors.textSecondary)),
                  ]),
                ),
              ]),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.createdAt != null ? df.format(order.createdAt!) : '-',
                      style: const TextStyle(fontSize: 11, color: MamoColors.textSecondary)),
                  Text(
                    order.deliveryMethod == 'cod'
                        ? 'COD'
                        : order.deliveryMethod == 'pickup'
                            ? 'Ambil di tempat'
                            : 'Dikirim',
                    style: const TextStyle(fontSize: 11, color: MamoColors.textMuted),
                  ),
                ]),
                Text(rupiah.format(order.totalAmount),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: MamoColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
