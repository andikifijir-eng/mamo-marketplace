import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Form jual barang (sesuai Jual-barang-1..4): foto -> detail -> harga -> lokasi.
class SellProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  const SellProductScreen({super.key, this.product});

  @override
  ConsumerState<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends ConsumerState<SellProductScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '1');
  final _location = TextEditingController();

  String _condition = 'used';
  String? _categoryId;
  final List<String> _imageUrls = [];
  bool _busy = false;
  bool _uploading = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _desc.text = p.description ?? '';
      _price.text = '${p.price}';
      _stock.text = '${p.stock}';
      _location.text = p.location ?? '';
      _condition = p.condition;
      _categoryId = p.categoryId;
      _imageUrls.addAll(p.images.map((e) => e.imageUrl));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      setState(() => _uploading = true);

      String url;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        url = await ref.read(uploadRepoProvider).uploadImageBytes(bytes, file.name);
      } else {
        url = await ref.read(uploadRepoProvider).uploadImage(file.path, fileName: file.name);
      }
      if (!mounted) return;
      setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      showSnack(context, 'Tambahkan minimal 1 foto produk', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(productRepoProvider);
      final payload = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': int.tryParse(_price.text.trim()) ?? 0,
        'stock': int.tryParse(_stock.text.trim()) ?? 1,
        'condition': _condition,
        'status': 'active',
        if (_categoryId != null) 'categoryId': _categoryId,
        if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
        'images': _imageUrls,
      };
      if (isEdit) {
        await repo.update(widget.product!.id, payload);
      } else {
        await repo.create(
          name: payload['name'] as String,
          description: payload['description'] as String?,
          price: payload['price'] as int,
          stock: payload['stock'] as int,
          condition: _condition,
          categoryId: _categoryId,
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          images: _imageUrls,
        );
      }
      ref.invalidate(sellerProductsProvider);
      ref.invalidate(homeProductsProvider);
      if (!mounted) return;
      showSnack(context, isEdit ? 'Listing diperbarui' : 'Listing berhasil dipublikasikan');
      context.go('/seller/products');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Listing' : 'Jual Barang')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto produk
            const Text('Foto Produk',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageUrls.asMap().entries.map((e) => Stack(children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: ProductImageBox(url: e.value, height: 96, width: 96),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageUrls.removeAt(e.key)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: MamoColors.danger, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ])),
                  GestureDetector(
                    onTap: _uploading ? null : _pickImage,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(MamoRadius.md),
                        border: Border.all(color: MamoColors.cardBorder),
                      ),
                      child: _uploading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 24, color: MamoColors.textMuted),
                                SizedBox(height: 6),
                                Text('Tambah',
                                    style: TextStyle(
                                        fontSize: 11, color: MamoColors.textMuted)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nama
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                hintText: 'Contoh: Monitor LG 24 inch IPS',
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Nama minimal 3 karakter'
                  : null,
            ),
            const SizedBox(height: 14),

            // Kategori
            const Text('Kategori',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            cats.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat kategori',
                  style: TextStyle(fontSize: 12, color: MamoColors.danger)),
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: list
                    .map((c) => ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(
                              () => _categoryId = _categoryId == c.id ? null : c.id),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Kondisi
            const Text('Kondisi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              ChoiceChip(
                label: const Text('Baru'),
                selected: _condition == 'new',
                onSelected: (_) => setState(() => _condition = 'new'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Bekas'),
                selected: _condition == 'used',
                onSelected: (_) => setState(() => _condition = 'used'),
              ),
            ]),
            const SizedBox(height: 16),

            // Harga & stok
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    prefixText: 'Rp ',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Harga tidak valid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Stok minimal 1';
                    return null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Deskripsi
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Jelaskan kondisi, kelengkapan, minus barang...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // Lokasi
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Lokasi',
                hintText: 'Contoh: Tembalang, Semarang',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Simpan Perubahan' : 'Publikasikan Listing'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
