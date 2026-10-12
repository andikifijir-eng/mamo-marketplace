import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Screen Pencarian sesuai target desain Figma (figma-screen-search.png):
/// 1. Top bar: Logo MAMO (mark custom + text) & icon Chat + Notifikasi (lingkaran putih + dot).
/// 2. Search bar: background abu-abu terang, rounded pill, icon cari kaca pembesar di kiri,
///    teks query atau tombol "Cari" biru di dalam bar.
/// 3. Filter chips horizontal: "Filter" (dengan icon slider & badge 1), "Terdekat", "Elektronik", "Bekas", dsb.
/// 4. Info hasil: Teks tebal 'Hasil untuk "..."' dan subtitle '[X] barang ditemukan di area kamu'.
/// 5. Grid 2 kolom produk: foto rounded corner besar, floating heart button di pojok kanan atas foto,
///    nama barang, harga bold, dan lokasi/kondisi ('Seperti baru · Banyumanik').
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const SearchScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  String? _categoryId;
  String? _condition;
  bool _terdekat = true;

  List<Product> _results = [];
  bool _loading = true;
  String? _error;

  static const _blue = Color(0xFF4355F9);

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(productRepoProvider).search(
            search: _query.text.trim().isEmpty ? null : _query.text.trim(),
            categoryId: _categoryId,
            condition: _condition,
            sort: _terdekat ? 'popular' : 'newest',
          );
      if (!mounted) return;
      setState(() {
        _results = res.products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final unreadNotifs = ref.watch(notificationsProvider).valueOrNull?.unread ?? 0;
    final queryText = _query.text.trim();

    final activeFilterCount = (_categoryId != null ? 1 : 0) +
        (_condition != null ? 1 : 0) +
        (_terdekat ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top Bar (Logo MAMO + Chat + Notifikasi) ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const CustomPaint(
                      painter: _MamoMarkPainter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MAMO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  _headerIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    hasDot: true,
                    onTap: () => context.go('/chat'),
                  ),
                  const SizedBox(width: 10),
                  _headerIconButton(
                    icon: Icons.notifications_none_rounded,
                    hasDot: unreadNotifs > 0,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),

            // ── 2. Search Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _query,
                        onSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          hintText: 'Cari barang yang kamu butuhkan...',
                          hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _query.clear();
                          _search();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    GestureDetector(
                      onTap: _search,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Cari',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Filter Chips Horizontal Row ─────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Filter trigger chip dengan badge count
                  GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: activeFilterCount > 0 ? const Color(0xFFEEF2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeFilterCount > 0 ? _blue : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: activeFilterCount > 0 ? _blue : const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: activeFilterCount > 0 ? _blue : const Color(0xFF1F2937),
                            ),
                          ),
                          if (activeFilterCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 17,
                              height: 17,
                              decoration: const BoxDecoration(
                                color: _blue,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Chip Terdekat
                  _filterChip(
                    label: 'Terdekat',
                    selected: _terdekat,
                    onTap: () {
                      setState(() => _terdekat = !_terdekat);
                      _search();
                    },
                  ),

                  // Chip Kategori (Elektronik, Buku, dsb)
                  ...cats.take(3).map((c) {
                    final selected = _categoryId == c.id;
                    return _filterChip(
                      label: c.name,
                      selected: selected,
                      onTap: () {
                        setState(() => _categoryId = selected ? null : c.id);
                        _search();
                      },
                    );
                  }),

                  // Chip Bekas / Baru
                  _filterChip(
                    label: 'Bekas',
                    selected: _condition == 'used',
                    onTap: () {
                      setState(() => _condition = _condition == 'used' ? null : 'used');
                      _search();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 4. Teks Informasi Hasil Pencarian ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    queryText.isNotEmpty
                        ? 'Hasil untuk "$queryText"'
                        : 'Jelajahi barang di sekitarmu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_results.length} barang ditemukan di area kamu',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 5. Grid Hasil Pencarian 2 Kolom ────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _search)
                      : _results.isEmpty
                          ? const EmptyState(
                              message: 'Tidak ada produk ditemukan.\nCoba kata kunci atau filter lain.',
                              icon: Icons.search_off_rounded,
                            )
                          : RefreshIndicator(
                              onRefresh: _search,
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (c, i) => _productGridCard(_results[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? _blue : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _productGridCard(Product p) {
    final conditionText = p.condition == 'new' ? 'Seperti baru' : 'Bekas';
    final locText = p.location ?? 'Banyumanik';

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar dengan rounded besar + floating heart
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ProductImageBox(
                    url: p.imageUrl,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    size: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),

          Text(
            rupiah.format(p.price),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),

          Text(
            '$conditionText · $locText',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1F2937)),
            if (hasDot)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Pencarian',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Urutkan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Terdekat'),
                  selected: _terdekat,
                  selectedColor: const Color(0xFFEEF2FF),
                  onSelected: (val) {
                    setState(() => _terdekat = val);
                    Navigator.pop(ctx);
                    _search();
                  },
                ),
                ChoiceChip(
                  label: const Text('Terbaru'),
                  selected: !_terdekat,
                  selectedColor: const Color(0xFFEEF2FF),
                  onSelected: (val) {
                    setState(() => _terdekat = !val);
                    Navigator.pop(ctx);
                    _search();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MamoMarkPainter extends CustomPainter {
  const _MamoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.28, size.height * 0.40);
    path.lineTo(size.width * 0.50, size.height * 0.65);
    path.lineTo(size.width * 0.72, size.height * 0.38);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
