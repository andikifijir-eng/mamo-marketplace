import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Search + filter inline sesuai desain Figma:
/// search bar rounded + tombol filter, filter chips horizontal (Terdekat,
/// kategori, Baru, Bekas), label "Hasil untuk '...'", grid 2 kolom.
/// Bottom nav otomatis dari ShellRoute.
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

  void _toggleCat(String id) {
    setState(() => _categoryId = _categoryId == id ? null : id);
    _search();
  }

  void _toggleCondition(String? c) {
    setState(() => _condition = _condition == c ? null : c);
    _search();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Urutkan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                  label: const Text('Terbaru'),
                  selected: !_terdekat,
                  onSelected: (_) => setSheet(() => _terdekat = false),
                ),
                ChoiceChip(
                  label: const Text('Terdekat'),
                  selected: _terdekat,
                  onSelected: (_) => setSheet(() => _terdekat = true),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Kondisi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _condition == null,
                  onSelected: (_) => setSheet(() => _condition = null),
                ),
                ChoiceChip(
                  label: const Text('Baru'),
                  selected: _condition == 'new',
                  onSelected: (_) => setSheet(() => _condition = 'new'),
                ),
                ChoiceChip(
                  label: const Text('Bekas'),
                  selected: _condition == 'used',
                  onSelected: (_) => setSheet(() => _condition = 'used'),
                ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(c);
                    _search();
                  },
                  child: const Text('Terapkan'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: back + search bar + filter icon ───────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBEC2C8)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Color(0xFF0B0B0B)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _query,
                        autofocus: widget.initialCategoryId == null,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Cari barang...',
                          hintStyle:
                              TextStyle(fontSize: 14, color: Color(0xFF999DA8)),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20, color: Color(0xFF999DA8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openFilterSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          size: 22, color: Color(0xFF4858E8)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter chips horizontal ────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Terdekat',
                      icon: Icons.location_on_rounded,
                      selected: _terdekat,
                      onTap: () {
                        setState(() => _terdekat = !_terdekat);
                        _search();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...cats.maybeWhen(
                      loading: () => <Widget>[],
                      error: (_, __) => <Widget>[],
                      orElse: () => <Widget>[],
                      data: (list) => list
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: c.name,
                                  selected: _categoryId == c.id,
                                  onTap: () => _toggleCat(c.id),
                                ),
                              ))
                          .toList(),
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _query.text.trim().isNotEmpty
                        ? 'Hasil untuk "${_query.text.trim()}"'
                        : 'Semua produk',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                              message:
                                  'Produk tidak ditemukan.\nCoba kata kunci atau filter lain.',
                              icon: Icons.search_off,
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

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
              Icon(icon,
                  size: 14,
                  color: selected
                      ? const Color(0xFF4858E8)
                      : const Color(0xFF6B7280)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF4858E8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
