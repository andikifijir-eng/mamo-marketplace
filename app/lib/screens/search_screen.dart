import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Search + filter (search text, kategori, harga, kondisi, sort).
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const SearchScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  late String? _categoryId = widget.initialCategoryId;
  RangeValues _priceRange = const RangeValues(0, 20000000);
  String? _condition;
  String _sort = 'newest';

  List<Product> _results = [];
  bool _loading = true;
  String? _error;
  int _total = 0;

  @override
  void initState() {
    super.initState();
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
            search: _query.text.trim(),
            categoryId: _categoryId,
            minPrice: _priceRange.start > 0 ? _priceRange.start.round() : null,
            maxPrice: _priceRange.end < 20000000 ? _priceRange.end.round() : null,
            condition: _condition,
            sort: _sort,
          );
      if (!mounted) return;
      setState(() {
        _results = res.products;
        _total = res.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = ApiClient.errorMessage(e); _loading = false; });
    }
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(MamoRadius.xl)),
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
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ref.watch(categoriesProvider).when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat kategori'),
                data: (cats) => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: cats.map((c) {
                    final selected = _categoryId == c.id;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      onSelected: (_) => setSheet(() => _categoryId = selected ? null : c.id),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Rentang Harga', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              RangeSlider(
                values: _priceRange,
                max: 20000000,
                divisions: 40,
                labels: RangeLabels(
                  rupiah.format(_priceRange.start),
                  rupiah.format(_priceRange.end),
                ),
                onChanged: (v) => setSheet(() => _priceRange = v),
              ),
              Center(
                child: Text('${rupiah.format(_priceRange.start)} - ${rupiah.format(_priceRange.end)}',
                    style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
              ),
              const SizedBox(height: 16),
              const Text('Kondisi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
              const SizedBox(height: 16),
              const Text('Urutkan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final s in const [
                  ('newest', 'Terbaru'),
                  ('price_asc', 'Harga termurah'),
                  ('price_desc', 'Harga tertinggi'),
                ])
                  ChoiceChip(
                    label: Text(s.$2),
                    selected: _sort == s.$1,
                    onSelected: (_) => setSheet(() => _sort = s.$1),
                  ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSheet(() {
                      _priceRange = const RangeValues(0, 20000000);
                      _condition = null;
                      _categoryId = null;
                      _sort = 'newest';
                    }),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(c); _search(); },
                    child: const Text('Terapkan'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Barang'),
        actions: [
          IconButton(onPressed: _openFilter, icon: const Icon(Icons.tune)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari barang, contoh: monitor',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)))
          else if (_error != null)
            Expanded(child: ErrorState(message: _error!, onRetry: _search))
          else if (_results.isEmpty)
            const Expanded(
              child: EmptyState(
                message: 'Produk tidak ditemukan.\nCoba kata kunci atau filter lain.',
                icon: Icons.search_off,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('$_total produk ditemukan',
                    style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
              ]),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }
}
