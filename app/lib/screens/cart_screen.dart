import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cartProvider);

    return Scaffold(
      appBar: const MamoHeader(showLogo: false),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.items.isEmpty) {
            return const EmptyState(
              message: 'Keranjang kamu masih kosong',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (c, i) {
                    final item = cart.items[i];
                    final p = item.product;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(MamoRadius.lg),
                        border: Border.all(color: MamoColors.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductImageBox(url: p.imageUrl, height: 76, width: 76),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                const SizedBox(height: 8),
                                Row(children: [
                                  _qtyBtn(Icons.remove, () async {
                                    if (item.quantity <= 1) return;
                                    try {
                                      await ref
                                          .read(cartRepoProvider)
                                          .updateQty(item.id, item.quantity - 1);
                                      ref.invalidate(cartProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        showSnack(context, ApiClient.errorMessage(e), error: true);
                                      }
                                    }
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w700)),
                                  ),
                                  _qtyBtn(Icons.add, () async {
                                    if (item.quantity >= p.stock) {
                                      showSnack(context, 'Stok tidak cukup', error: true);
                                      return;
                                    }
                                    try {
                                      await ref
                                          .read(cartRepoProvider)
                                          .updateQty(item.id, item.quantity + 1);
                                      ref.invalidate(cartProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        showSnack(context, ApiClient.errorMessage(e), error: true);
                                      }
                                    }
                                  }),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () async {
                                      await ref.read(cartRepoProvider).remove(item.id);
                                      ref.invalidate(cartProvider);
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: MamoColors.danger),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: MamoColors.cardBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 14, color: MamoColors.textSecondary)),
                        Text(rupiah.format(cart.total),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: MamoColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/checkout'),
                      child: const Text('Checkout'),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: MamoColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16),
        ),
      );
}
