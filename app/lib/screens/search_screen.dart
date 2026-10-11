import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Search + filter inline sesuai desain Figma:
/// search bar di atas, filter chips (Terdekat, kategori, kondisi) horizontal,
/// label "Hasil untuk '...'", grid produk 2 kolom.
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
  final String _sort = 'newest'; // ponytail: reserved for future sort dropdown
  bool _terdekat = false;

  List<Product> _results = [];
  bool _loading = true;
  String? _error;

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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(productRepoProvider).search(
            search: _query.text.trim().isEmpty ? null : _query.text.trim(),
            categoryId: _categoryId,
            condition: _condition,
            sort: _terdekat ? 'popular' : _sort,
          );
      if (!mounted) return;
      setState(() {
        _results = res.products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = ApiClient.errorMessage(e); _loading = false; });
    }
  }

  void _toggleCat(String id) {
    setState(() => _categoryId = _categoryId == id ? null : id);
    _search();
  }

  void _toggleCondition(String? c) {
    setState(() => _condition = _condition == c ? null : c);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + search bar ───────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: Row(
                children: [
                  _CircleBack(onTap: () {
                    if (canPop) {
                      router!.pop();
                    } else {
                      context.go('/home');
                    }
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _query,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari barang...',
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999DA8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF999DA8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          suffixIcon: _query.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () { _query.clear(); _search(); },
                                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF999DA8)),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter chips ───────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Terdekat',
                      icon: Icons.location_on_rounded,
                      selected: _terdekat,
                      onTap: () { setState(() => _terdekat = !_terdekat); _search(); },
                    ),
                    const SizedBox(width: 8),
                    ...cats.maybeWhen(
                      loading: () => <Widget>[],
                      error: (_, __) => <Widget>[],
                      orElse: () => <Widget>[],
                      data: (list) => list.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: c.name,
                          selected: _categoryId == c.id,
                          onTap: () => _toggleCat(c.id),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Baru',
                      selected: _condition == 'new',
                      onTap: () => _toggleCondition('new'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bekas',
                      selected: _condition == 'used',
                      onTap: () => _toggleCondition('used'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hasil label ────────────────────────────────────────
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _query.text.trim().isNotEmpty
                        ? 'Hasil untuk "${_query.text.trim()}"'
                        : 'Semua produk',
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF172039),
                    ),
                  ),
                ),
              ),

            // ── Hasil grid ─────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _search)
                      : _results.isEmpty
                          ? const EmptyState(
                              message: 'Produk tidak ditemukan.\nCoba kata kunci atau filter lain.',
                              icon: Icons.search_off,
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _results.length,
                              itemBuilder: (c, i) {
                                final p = _results[i];
                                return ProductCard(
                                  name: p.name,
                                  price: p.price,
                                  imageUrl: p.imageUrl,
                                  location: p.location ?? p.categoryName,
                                  conditionLabel: p.conditionLabel,
                                  onTap: () => context.push('/product/${p.id}'),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Komponen kecil ─────────────────────────────────────────────

class _CircleBack extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBEC2C8)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0B0B0B)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF0FF) : const Color(0xFFF2F3F6),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: const Color(0xFF4858E8), width: 1.2)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? const Color(0xFF4858E8) : const Color(0xFF6B7280)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF4858E8) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
