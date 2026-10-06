import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Detail order + aksi sesuai role:
/// - seller: accept / process / ready / reject
/// - buyer: cancel (pending) / complete (ready) / review (completed)
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await ref.read(orderRepoProvider).detail(widget.orderId);
      if (mounted) setState(() => _order = o);
    } catch (_) {}
  }

  Future<void> _change(String status) async {
    setState(() => _busy = true);
    try {
      await ref.read(orderRepoProvider).updateStatus(widget.orderId, status);
      await _load();
      if (mounted) showSnack(context, 'Status diperbarui ke "${Order.statusLabels[status]}"');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    int rating = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('Beri Ulasan'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setD(() => rating = i + 1),
                  icon: Icon(i < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFD97706)),
                ),
              ),
            ),
            TextField(
              controller: comment,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tulis pengalamanmu (opsional)'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kirim')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRepoProvider).review(
            orderId: widget.orderId,
            rating: rating,
            comment: comment.text.trim().isEmpty ? null : comment.text.trim(),
          );
      await _load();
      if (mounted) showSnack(context, 'Terima kasih atas ulasannya!');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authProvider).user?.id;
    final o = _order;
    final df = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    final isSeller = o != null && o.sellerId == myId;
    final isBuyer = o != null && o.buyerId == myId;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: o == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        StatusPill.order(o.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(o.createdAt != null ? df.format(o.createdAt!) : '',
                        style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
                    const Divider(height: 24),
                    _row('Pembeli', o.buyerName ?? '-'),
                    _row('Penjual', o.sellerName ?? '-'),
                    _row('Metode',
                        o.deliveryMethod == 'cod'
                            ? 'COD / Ketemuan'
                            : o.deliveryMethod == 'pickup'
                                ? 'Ambil di tempat'
                                : 'Dikirim'),
                    if (o.deliveryAddress != null && o.deliveryAddress!.isNotEmpty)
                      _row('Alamat', o.deliveryAddress!),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Item',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...o.items.map((it) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(MamoRadius.md),
                        border: Border.all(color: MamoColors.cardBorder),
                      ),
                      child: Row(children: [
                        ProductImageBox(url: it.productImage, height: 48, width: 48),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.productName ?? 'Produk',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('${it.quantity} x ${rupiah.format(it.price)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: MamoColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(rupiah.format(it.subtotal),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                    )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontSize: 14, color: MamoColors.textSecondary)),
                    Text(rupiah.format(o.totalAmount),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: MamoColors.primary)),
                  ],
                ),
                const SizedBox(height: 24),

                // ===== Aksi seller =====
                if (isSeller) ...[
                  if (o.status == 'pending')
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _change('rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MamoColors.danger,
                            side: const BorderSide(color: MamoColors.dangerBg),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy ? null : () => _change('accepted'),
                          child: const Text('Terima'),
                        ),
                      ),
                    ]),
                  if (o.status == 'accepted')
                    ElevatedButton(
                      onPressed: _busy ? null : () => _change('processed'),
                      child: const Text('Proses Pesanan'),
                    ),
                  if (o.status == 'processed')
                    ElevatedButton(
                      onPressed: _busy ? null : () => _change('ready'),
                      child: const Text('Tandai Siap'),
                    ),
                ],

                // ===== Aksi buyer =====
                if (isBuyer) ...[
                  if (o.status == 'pending')
                    OutlinedButton(
                      onPressed: _busy ? null : () => _change('cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MamoColors.danger,
                        side: const BorderSide(color: MamoColors.dangerBg),
                      ),
                      child: const Text('Batalkan Pesanan'),
                    ),
                  if (o.status == 'ready')
                    ElevatedButton(
                      onPressed: _busy ? null : () => _change('completed'),
                      child: const Text('Pesanan Diterima (Selesai)'),
                    ),
                  if (o.status == 'completed' && !o.hasReview)
                    ElevatedButton.icon(
                      onPressed: _review,
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Beri Ulasan'),
                    ),
                  if (o.status == 'completed' && o.hasReview)
                    const Center(
                      child: Text('Kamu sudah memberi ulasan untuk pesanan ini',
                          style: TextStyle(fontSize: 12, color: MamoColors.textMuted)),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 12.5, height: 1.4)),
            ),
          ],
        ),
      );
}
