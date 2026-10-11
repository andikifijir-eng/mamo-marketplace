import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Detail produk sesuai desain Figma — fokus COD.
/// Header abu, gambar besar, harga di kartu kuning, nama, deskripsi
/// collapsible, kartu penjual + rating + Chat, tombol bawah "Beli COD".
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
  bool _descExpanded = false;

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
      backgroundColor: Colors.white,
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
          final router = GoRouter.maybeOf(context);
          final canPop = router?.canPop() ?? false;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Gambar produk + header overlay ───────────────
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _imageIndex = i),
                            itemBuilder: (c, i) => ProductImageBox(
                              url: images[i].isEmpty ? null : images[i],
                              height: 300,
                              width: double.infinity,
                              radius: 0,
                            ),
                          ),
                          // Header overlay
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Row(
                                  children: [
                                    _CircleBtn(
                                      icon: Icons.arrow_back_ios_new_rounded,
                                      onTap: () {
                                        if (canPop) {
                                          router!.pop();
                                        } else {
                                          context.go('/home');
                                        }
                                      },
                                      bg: Colors.white,
                                    ),
                                    const Spacer(),
                                    _CircleBtn(
                                      icon: Icons.share_outlined,
                                      onTap: () {},
                                      bg: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    _CircleBtn(
                                      icon: _fav || d.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      iconColor: _fav || d.isFavorite
                                          ? const Color(0xFFEF4444)
                                          : null,
                                      onTap: _busy ? null : () => _toggleFavorite(p.id),
                                      bg: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Page indicator
                          if (images.length > 1)
                            Positioned(
                              bottom: 10, left: 0, right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _imageIndex ? 18 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: i == _imageIndex
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                )),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Nama + Harga ──────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700,
                                color: Color(0xFF0B0B0B), height: 1.3)),
                          const SizedBox(height: 10),
                          // Harga dalam kartu kuning
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3DD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rupiah.format(p.price),
                                          style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.w800,
                                            color: Color(0xFF0B0B0B))),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        StatusPill(
                                          label: p.conditionLabel,
                                          color: const Color(0xFF4858E8),
                                          bg: const Color(0xFFEEF0FF),
                                          icon: Icons.sell_outlined,
                                        ),
                                        const SizedBox(width: 6),
                                        StatusPill(
                                          label: 'Stok ${p.stock}',
                                          color: p.stock > 0
                                              ? const Color(0xFF168A61)
                                              : const Color(0xFFEF4444),
                                          bg: p.stock > 0
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFFEE2E2),
                                          icon: Icons.inventory_2_outlined,
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                if (d.rating != null)
                                  Column(
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.star,
                                            size: 16, color: Color(0xFFEAB854)),
                                        const SizedBox(width: 2),
                                        Text(d.rating!.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.w800,
                                              color: Color(0xFF0B0B0B))),
                                      ]),
                                      Text('${d.ratingCount} ulasan',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF999DA8))),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Deskripsi ────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deskripsi',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: Color(0xFF0B0B0B))),
                          const SizedBox(height: 8),
                          Text(
                            (p.description == null || p.description!.isEmpty)
                                ? 'Penjual belum menuliskan deskripsi.'
                                : p.description!,
                            style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
                            maxLines: _descExpanded ? null : 3,
                            overflow: _descExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                          if (p.description != null && p.description!.length > 120)
                            GestureDetector(
                              onTap: () => setState(() => _descExpanded = !_descExpanded),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _descExpanded ? 'Sembunyikan' : 'Baca selengkapnya',
                                  style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: Color(0xFF4858E8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Penjual ──────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nama Penjual',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: Color(0xFF0B0B0B))),
                          const SizedBox(height: 12),
                          Row(children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEEF0FF),
                              backgroundImage: (p.sellerAvatar != null &&
                                      p.sellerAvatar!.isNotEmpty)
                                  ? NetworkImage(p.sellerAvatar!)
                                  : null,
                              child: (p.sellerAvatar == null || p.sellerAvatar!.isEmpty)
                                  ? Text(
                                      (p.sellerName ?? 'P').characters.first.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF4858E8),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.sellerName ?? 'Penjual',
                                      style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: Color(0xFF0B0B0B))),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 12, color: Color(0xFF999DA8)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        p.location ?? p.categoryName ?? 'Lokasi tidak disebutkan',
                                        style: const TextStyle(
                                          fontSize: 11, color: Color(0xFF6B7280)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _chatSeller(p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF0FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded,
                                        size: 14, color: Color(0xFF4858E8)),
                                    SizedBox(width: 4),
                                    Text('Chat Penjual',
                                        style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                          color: Color(0xFF4858E8))),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    // ── Ulasan ───────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ulasan Pembeli',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: Color(0xFF0B0B0B))),
                          const SizedBox(height: 8),
                          _Reviews(productId: p.id),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom bar: langsung ke Chat ─────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_busy ||
                              p.sellerId == ref.read(authProvider).user?.id)
                          ? null
                          : () => _chatSeller(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4858E8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_rounded,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Chat Penjual',
                                  style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Komponen kecil ─────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color bg;
  final VoidCallback? onTap;
  const _CircleBtn({
    required this.icon,
    this.iconColor,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18,
            color: iconColor ?? const Color(0xFF0B0B0B)),
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
                  backgroundColor: const Color(0xFFEEF0FF),
                  child: Text(reviewer.toString().characters.first.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12, color: Color(0xFF4858E8),
                        fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reviewer,
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(i < rating ? Icons.star : Icons.star_border,
                              size: 13, color: const Color(0xFFEAB854)),
                        ),
                      ),
                      if (r['comment'] != null) ...[
                        const SizedBox(height: 4),
                        Text('${r['comment']}',
                            style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280), height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
