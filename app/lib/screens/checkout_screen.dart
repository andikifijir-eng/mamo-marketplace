import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Checkout end-to-end: pilih item, alamat, metode (COD/delivery), lalu buat order.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  String _method = 'cod';
  bool _busy = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.items.isEmpty) {
      showSnack(context, 'Keranjang kosong', error: true);
      return;
    }
    if (_method != 'pickup' && _address.text.trim().isEmpty) {
      showSnack(context, 'Alamat wajib diisi untuk COD/pengiriman', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final orders = await ref.read(orderRepoProvider).checkout(
            cartItemIds: cart.items.map((e) => e.id).toList(),
            deliveryMethod: _method,
            deliveryAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
          );
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      showSnack(context, '${orders.length} pesanan berhasil dibuat');
      context.go('/orders');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(message: ApiClient.errorMessage(e)),
        data: (cart) {
          if (cart.items.isEmpty) {
            return const EmptyState(message: 'Tidak ada item untuk di-checkout');
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Item Pesanan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...cart.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(MamoRadius.md),
                            border: Border.all(color: MamoColors.cardBorder),
                          ),
                          child: Row(children: [
                            ProductImageBox(url: item.product.imageUrl, height: 52, width: 52),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('${item.quantity} x ${rupiah.format(item.product.price)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: MamoColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(rupiah.format(item.subtotal),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ]),
                        )),
                    const SizedBox(height: 12),
                    const Text('Metode Transaksi',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _methodTile('cod', 'COD / Ketemuan', 'Bayar langsung saat bertemu',
                        Icons.handshake_outlined),
                    _methodTile('delivery', 'Dikirim', 'Dikirim ke alamat kamu',
                        Icons.local_shipping_outlined),
                    _methodTile('pickup', 'Ambil di Tempat', 'Ambil sendiri di lokasi penjual',
                        Icons.storefront_outlined),
                    const SizedBox(height: 16),
                    if (_method != 'pickup') ...[
                      const Text('Alamat',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _address,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Kos Putri Ayu, Jl. Prof. Sudarto, Tembalang',
                        ),
                      ),
                    ],
                  ],
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
                        const Text('Total bayar',
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
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Buat Pesanan'),
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

  Widget _methodTile(String value, String title, String subtitle, IconData icon) {
    final selected = _method == value;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MamoRadius.md),
          border: Border.all(
            color: selected ? MamoColors.primary : MamoColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? MamoColors.infoBg : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(MamoRadius.sm),
            ),
            child: Icon(icon, size: 19,
                color: selected ? MamoColors.primary : MamoColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: MamoColors.textSecondary)),
            ]),
          ),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20, color: selected ? MamoColors.primary : MamoColors.textMuted),
        ]),
      ),
    );
  }
}
