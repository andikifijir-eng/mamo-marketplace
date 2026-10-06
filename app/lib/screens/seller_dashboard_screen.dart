import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Dashboard penjual: listing, order, statistik, rating, penjualan 7 hari.
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Penjual'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(sellerDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(sellerDashboardProvider),
        ),
        data: (d) {
          final sales = (d['salesLast7Days'] as List?) ?? [];
          final maxSale = sales.fold<int>(1, (m, e) {
            final v = (e['amount'] ?? 0) as int;
            return v > m ? v : m;
          });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerDashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stat utama
                Row(children: [
                  Expanded(child: _stat('Total Listing', '${d['totalListings'] ?? 0}',
                      Icons.inventory_2_outlined, MamoColors.primary, MamoColors.infoBg)),
                  const SizedBox(width: 12),
                  Expanded(child: _stat('Listing Aktif', '${d['activeListings'] ?? 0}',
                      Icons.check_circle_outline, MamoColors.success, MamoColors.successBg)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _stat('Terjual', '${d['soldListings'] ?? 0}',
                      Icons.sell_outlined, const Color(0xFFD97706), MamoColors.warningBg)),
                  const SizedBox(width: 12),
                  Expanded(child: _stat('Order Pending', '${d['pendingOrders'] ?? 0}',
                      Icons.schedule, MamoColors.primary, MamoColors.infoBg)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _stat('Pendapatan', rupiah.format(d['revenue'] ?? 0),
                      Icons.payments_outlined, MamoColors.success, MamoColors.successBg,
                      small: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat(
                      'Rating',
                      d['rating']?['average'] != null
                          ? '${(d['rating']['average'] as num).toStringAsFixed(1)} '
                              '(${d['rating']['count']})'
                          : '-',
                      Icons.star_outline,
                      const Color(0xFFD97706),
                      MamoColors.warningBg,
                    ),
                  ),
                ]),
                if ((d['unreadChats'] ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MamoColors.infoBg,
                      borderRadius: BorderRadius.circular(MamoRadius.lg),
                    ),
                    child: Row(children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 20, color: MamoColors.primary),
                      const SizedBox(width: 10),
                      Text('${d['unreadChats']} pesan belum dibalas',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: MamoColors.primary)),
                    ]),
                  ),
                ],

                // Grafik penjualan 7 hari
                const SectionHeader(title: 'Penjualan 7 Hari Terakhir'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(MamoRadius.lg),
                    border: Border.all(color: MamoColors.cardBorder),
                  ),
                  child: sales.isEmpty
                      ? const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text('Belum ada penjualan selesai',
                                style: TextStyle(
                                    fontSize: 12, color: MamoColors.textMuted)),
                          ),
                        )
                      : SizedBox(
                          height: 140,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: sales.map<Widget>((e) {
                              final amount = (e['amount'] ?? 0) as int;
                              final ratio = amount / maxSale;
                              final dt = DateTime.tryParse('${e['date']}');
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        amount > 0
                                            ? '${(amount / 1000).round()}k'
                                            : '',
                                        style: const TextStyle(
                                            fontSize: 9, color: MamoColors.textSecondary),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        height: (100 * ratio).clamp(4, 100).toDouble(),
                                        decoration: BoxDecoration(
                                          gradient: MamoColors.brandGradient,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        dt != null ? '${dt.day}/${dt.month}' : '-',
                                        style: const TextStyle(
                                            fontSize: 9, color: MamoColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),

                // Aksi cepat
                const SectionHeader(title: 'Kelola'),
                _action(context, Icons.add_box_outlined, 'Jual Barang Baru',
                    () => context.push('/sell')),
                _action(context, Icons.inventory_2_outlined, 'Listing Saya',
                    () => context.push('/seller/products')),
                _action(context, Icons.receipt_long_outlined, 'Pesanan Masuk',
                    () => context.push('/orders?as=seller')),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color, Color bg,
      {bool small = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MamoRadius.lg),
        border: Border.all(color: MamoColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 11, color: MamoColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: small ? 14 : 18,
                fontWeight: FontWeight.w800,
                color: MamoColors.textPrimary)),
      ]),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MamoRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MamoRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MamoRadius.md),
              border: Border.all(color: MamoColors.cardBorder),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: MamoColors.primary),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500))),
              const Icon(Icons.chevron_right, size: 20, color: MamoColors.textMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
