import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _fav = false;
  bool _busy = false;
  int _imageIndex = 0;

  Future<void> _toggleFavorite(String productId) async {
    setState(() => _busy = true);
    try {
      if (_fav) {
        await ref.read(productRepoProvider).removeFavorite(productId);
      } else {
        await ref.read(productRepoProvider).addFavorite(productId);
      }
      if (!mounted) return;
      setState(() => _fav = !_fav);
      ref.invalidate(favoritesProvider);
      showSnack(context, _fav ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addToCart(String productId) async {
    setState(() => _busy = true);
    try {
      await ref.read(cartRepoProvider).add(productId);
      ref.invalidate(cartProvider);
      if (mounted) {
        showSnack(context, 'Masuk ke keranjang');
      }
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chatSeller(Product p) async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;
    try {
      final conv = await ref.read(chatRepoProvider)
          .open(sellerId: p.sellerId, productId: p.id, myId: auth.user!.id);
      if (!mounted) return;
      context.push('/chat/${conv.id}', extra: conv.otherName ?? 'Penjual');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: [
          async.maybeWhen(
            data: (d) => IconButton(
              onPressed: _busy ? null : () => _toggleFavorite(d.product.id),
              icon: Icon(
                _fav || d.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _fav || d.isFavorite ? MamoColors.danger : null,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (d) {
          final p = d.product;
          _fav = d.isFavorite;
          final images = p.images.isEmpty ? [''] : p.images.map((e) => e.imageUrl).toList();
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Gambar
                    SizedBox(
                      height: 280,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemBuilder: (c, i) => ProductImageBox(
                          url: images[i].isEmpty ? null : images[i],
                          height: 280,
                          width: double.infinity,
                          radius: 0,
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _imageIndex ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _imageIndex
                                    ? MamoColors.primary
                                    : MamoColors.cardBorder,
                                borderRadius: BorderRadius.circular(MamoRadius.pill),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rupiah.format(p.price),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: MamoColors.primary)),
                          const SizedBox(height: 8),
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, height: 1.35)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, children: [
                            StatusPill(
                              label: p.conditionLabel,
                              color: MamoColors.primary,
                              bg: MamoColors.infoBg,
                              icon: Icons.sell_outlined,
                            ),
                            StatusPill(
                              label: 'Stok ${p.stock}',
                              color: p.stock > 0 ? MamoColors.success : MamoColors.danger,
                              bg: p.stock > 0 ? MamoColors.successBg : MamoColors.dangerBg,
                              icon: Icons.inventory_2_outlined,
                            ),
                            if (d.rating != null)
                              StatusPill(
                                label: '${d.rating!.toStringAsFixed(1)} (${d.ratingCount})',
                                color: Color(0xFFD97706),
                                bg: MamoColors.warningBg,
                                icon: Icons.star,
                              ),
                          ]),
                          const Divider(height: 32),
                          // Info penjual
                          Row(children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: MamoColors.infoBg,
                              backgroundImage: (p.sellerAvatar != null &&
                                      p.sellerAvatar!.isNotEmpty)
                                  ? NetworkImage(p.sellerAvatar!)
                                  : null,
                              child: (p.sellerAvatar == null || p.sellerAvatar!.isEmpty)
                                  ? Text(
                                      (p.sellerName ?? 'P').characters.first.toUpperCase(),
                                      style: const TextStyle(
                                          color: MamoColors.primary, fontWeight: FontWeight.w700))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.sellerName ?? 'Penjual',
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 12, color: MamoColors.textMuted),
                                    const SizedBox(width: 2),
                                    Text(p.location ?? p.categoryName ?? 'Lokasi tidak disebutkan',
                                        style: const TextStyle(
                                            fontSize: 11, color: MamoColors.textSecondary)),
                                  ]),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _chatSeller(p),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(horizontal: 14)),
                              child: const Text('Chat', style: TextStyle(fontSize: 13)),
                            ),
                          ]),
                          const Divider(height: 32),
                          const Text('Deskripsi',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            (p.description == null || p.description!.isEmpty)
                                ? 'Penjual belum menuliskan deskripsi.'
                                : p.description!,
                            style: const TextStyle(
                                fontSize: 13, color: MamoColors.textSecondary, height: 1.6),
                          ),
                          const Divider(height: 32),
                          const Text('Ulasan Pembeli',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          _Reviews(productId: p.id),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom bar aksi
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: MamoColors.cardBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(children: [
                    OutlinedButton(
                      onPressed: _busy ? null : () => _chatSeller(p),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(52, 50),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_busy || p.stock < 1 || p.sellerId == ref.read(authProvider).user?.id)
                            ? null
                            : () => _addToCart(p.id),
                        child: const Text('+ Keranjang'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_busy || p.stock < 1 || p.sellerId == ref.read(authProvider).user?.id)
                            ? null
                            : () async {
                                await _addToCart(p.id);
                                if (context.mounted) context.push('/checkout');
                              },
                        child: Text(p.stock < 1 ? 'Stok Habis' : 'Beli Sekarang'),
                      ),
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
}

class _Reviews extends ConsumerWidget {
  final String productId;
  const _Reviews({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productReviewsProvider(productId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text(ApiClient.errorMessage(e),
          style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
      data: (list) {
        if (list.isEmpty) {
          return const Text('Belum ada ulasan untuk produk ini.',
              style: TextStyle(fontSize: 12, color: MamoColors.textMuted));
        }
        return Column(
          children: list.map((r) {
            final reviewer = (r['reviewer']?['profile']?['fullName']) ?? 'Pembeli';
            final rating = (r['rating'] ?? 0) as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: MamoColors.infoBg,
                  child: Text(reviewer.toString().characters.first.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12, color: MamoColors.primary, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(reviewer,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(i < rating ? Icons.star : Icons.star_border,
                            size: 13, color: Color(0xFFD97706)),
                      ),
                    ),
                    if (r['comment'] != null) ...[
                      const SizedBox(height: 4),
                      Text('${r['comment']}',
                          style: const TextStyle(
                              fontSize: 12, color: MamoColors.textSecondary, height: 1.5)),
                    ],
                  ]),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
