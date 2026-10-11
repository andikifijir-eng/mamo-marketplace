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

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sellerProductsProvider);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (canPop) {
              router!.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Listing Saya',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0B0B0B))),
        actions: [
          IconButton(
            onPressed: () => context.push('/sell'),
            icon: const Icon(Icons.add, size: 24),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: const Color(0xFF4858E8),
              unselectedLabelColor: const Color(0xFF999DA8),
              indicatorColor: const Color(0xFF4858E8),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Aktif'),
                Tab(text: 'Pending'),
                Tab(text: 'Terjual'),
              ],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(sellerProductsProvider),
        ),
        data: (products) {
          return TabBarView(
            controller: _tab,
            children: [
              _productList(products, 'active'),
              _productList(products, 'pending'),
              _productList(products, 'sold'),
            ],
          );
        },
      ),
    );
  }

  Widget _productList(List<Product> all, String status) {
    final products = all.where((p) => p.status == status).toList();
    if (products.isEmpty) {
      return EmptyState(
        message: 'Belum ada listing $status',
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
        itemBuilder: (c, i) => _productCard(products[i]),
      ),
    );
  }

  Widget _productCard(Product p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImageBox(url: p.imageUrl, height: 70, width: 70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF172039))),
                const SizedBox(height: 4),
                Text(rupiah.format(p.price),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: MamoColors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusPill.order(p.status),
                    const Spacer(),
                    Text('${p.favoriteCount} disimpan',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF999DA8))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
