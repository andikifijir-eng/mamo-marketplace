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
import '../data/wilayah.dart';

/// Form jual barang — multi-step wizard sesuai desain Figma:
/// Langkah 1: Foto → Langkah 2: Info barang → Langkah 3: Sukses.
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
  String? _province;
  String? _city;
  final List<String> _imageUrls = [];
  bool _busy = false;
  bool _uploading = false;

  int _step = 0; // 0=foto, 1=info, 2=sukses
  String? _createdName;

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
      // parse existing location: "Kota, Provinsi"
      if (p.location != null && p.location!.contains(', ')) {
        final parts = p.location!.split(', ');
        _city = parts[0].trim();
        _province = parts[1].trim();
      }
      _condition = p.condition;
      _categoryId = p.categoryId;
      _imageUrls.addAll(p.images.map((e) => e.imageUrl));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock]) {
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

  void _next() {
    if (_step == 0) {
      if (_imageUrls.isEmpty) {
        showSnack(context, 'Tambahkan minimal 1 foto produk', error: true);
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else if (_step == 1) {
      setState(() => _step = 0);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(productRepoProvider);
      final payload = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': int.tryParse(_price.text.trim()) ?? 0,
        'stock': int.tryParse(_stock.text.trim()) ?? 1,
        'condition': _condition == 'like_new' ? 'used' : _condition,
        'status': 'active',
        if (_categoryId != null) 'categoryId': _categoryId,
        if (_city != null && _province != null)
          'location': '$_city, $_province',
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
          condition: _condition == 'like_new' ? 'used' : _condition,
          categoryId: _categoryId,
          location: (_city != null && _province != null) ? '$_city, $_province' : null,
          images: _imageUrls,
        );
      }
      ref.invalidate(sellerProductsProvider);
      ref.invalidate(homeProductsProvider);
      if (!mounted) return;
      setState(() {
        _createdName = _name.text.trim();
        _step = 2;
      });
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Stepper pill ──────────────────────────────────────────────
  Widget _stepDot(int i) {
    final active = i <= _step;
    final label = ['Foto', 'Info', 'Selesai'][i];
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: active ? MamoColors.primary : const Color(0xFFE8E8E8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: active ? Colors.white : MamoColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500,
                color: i == _step ? MamoColors.textPrimary : MamoColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _stepper() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
        child: Row(
          children: [
            _stepDot(0),
            _connector(0),
            _stepDot(1),
            _connector(1),
            _stepDot(2),
          ],
        ),
      );

  Widget _connector(int i) {
    final active = i < _step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: active ? MamoColors.primary : const Color(0xFFE8E8E8),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    final titles = ['Jual Barang', 'Jual Barang', 'Preview'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Row(
        children: [
          _CircleButton(
            icon: _step == 2 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (_step == 2) {
                context.go('/home');
              } else {
                _back();
              }
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              titles[_step],
              style: const TextStyle(
                fontSize: 19.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B0B0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Langkah 1: Foto ───────────────────────────────────────────
  Widget _stepFoto() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 100),
      children: [
        const _SectionLabel('Ambil foto barangmu'),
        const SizedBox(height: 4),
        Text('Foto yang bagus, cepat laku.',
            style: TextStyle(fontSize: 13, color: MamoColors.textMuted)),
        const SizedBox(height: 20),

        // Foto grid
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imageUrls.asMap().entries.map((e) => Stack(children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: ProductImageBox(url: e.value, height: 110, width: 110, radius: 14),
                    ),
                    Positioned(
                      top: 4, right: 16,
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
              // Tombol ambil foto
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFBEC2C8),
                        style: BorderStyle.solid,
                        width: 1),
                  ),
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined,
                                size: 28, color: MamoColors.primary),
                            const SizedBox(height: 6),
                            Text(_imageUrls.isEmpty ? 'Ambil foto' : 'Tambah',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: MamoColors.primary)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Tips foto
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 18, color: Color(0xFFB7791F)),
                const SizedBox(width: 6),
                const Text('Tips foto yang menarik',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFFB7791F))),
              ]),
              const SizedBox(height: 8),
              ...[
                'Pencahayaan terang, latar bersih',
                'Tampilkan seluruh bagian barang',
              ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFFB7791F)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(t,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8B6914)))),
                    ]),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ── Langkah 2: Info barang ────────────────────────────────────
  Widget _stepInfo() {
    final cats = ref.watch(categoriesProvider);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 100),
        children: [
          const _SectionLabel('Ceritakan barangmu'),
          const SizedBox(height: 4),
          Text('Detail yang lengkap membantu pembeli lebih yakin',
              style: TextStyle(fontSize: 13, color: MamoColors.textMuted)),
          const SizedBox(height: 16),

          // Nama
          _FieldLabel('Nama barang'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Masukkan nama barang'),
            validator: (v) =>
                (v == null || v.trim().length < 3) ? 'Nama minimal 3 karakter' : null,
          ),
          const SizedBox(height: 16),

          // Harga
          _FieldLabel('Harga'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              hintText: 'Masukkan harga barang',
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n <= 0) return 'Harga tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Kategori — dropdown
          _FieldLabel('Kategori'),
          const SizedBox(height: 6),
          cats.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Gagal memuat kategori',
                style: TextStyle(fontSize: 12, color: MamoColors.danger)),
            data: (list) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(hintText: 'Pilih kategori'),
              items: list
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          const SizedBox(height: 16),

          // Kondisi — Baru / Seperti Baru / Bekas
          _FieldLabel('Kondisi'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _condition,
            decoration: const InputDecoration(hintText: 'Pilih kondisi'),
            items: const [
              DropdownMenuItem(value: 'new', child: Text('Baru')),
              DropdownMenuItem(value: 'like_new', child: Text('Seperti Baru')),
              DropdownMenuItem(value: 'used', child: Text('Bekas')),
            ],
            onChanged: (v) => setState(() => _condition = v ?? 'used'),
          ),
          const SizedBox(height: 8),
          Text(
            'Barang dengan kondisi lebih baik cenderung lebih cepat laku',
            style: TextStyle(fontSize: 11, color: MamoColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Stok
          _FieldLabel('Stok'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _stock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '1'),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1) return 'Stok minimal 1';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Deskripsi
          _FieldLabel('Deskripsi'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _desc,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Jelaskan kondisi, kelengkapan, minus barang...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Lokasi — dropdown Provinsi + Kota
          _FieldLabel('Lokasi barang'),
          const SizedBox(height: 4),
          Text('Pilih lokasi barang agar pembeli lebih mudah menemukanmu.',
              style: TextStyle(fontSize: 11, color: MamoColors.textMuted)),
          const SizedBox(height: 8),

          // Provinsi
          DropdownButtonFormField<String>(
            initialValue: _province,
            decoration: const InputDecoration(
              hintText: 'Pilih provinsi',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
            items: provinsiList
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() {
              _province = v;
              _city = null; // reset kota saat provinsi berubah
            }),
            validator: (v) => v == null ? 'Pilih provinsi' : null,
          ),
          const SizedBox(height: 12),

          // Kota
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: const InputDecoration(hintText: 'Pilih kota'),
            items: (_province != null && wilayahIndonesia.containsKey(_province))
                ? wilayahIndonesia[_province]!
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList()
                : [],
            onChanged: (_province == null) ? null : (v) => setState(() => _city = v),
            validator: (v) => v == null ? 'Pilih kota' : null,
          ),
        ],
      ),
    );
  }

  // ── Langkah 3: Sukses ─────────────────────────────────────────
  Widget _stepSukses() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon sukses
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 48, color: Color(0xFF168A61)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Listing Terkirim!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: Color(0xFF0B0B0B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Sedang kami periksa.\nBarang akan ditampilkan setelah diverifikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: MamoColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 32),

            // Preview kartu
            if (_imageUrls.isNotEmpty || _createdName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDF1F5)),
                ),
                child: Row(children: [
                  if (_imageUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ProductImageBox(
                          url: _imageUrls.first, height: 56, width: 56, radius: 10),
                    ),
                  if (_imageUrls.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_createdName ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Color(0xFF0B0B0B)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Pending Review',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: Color(0xFFD3454D))),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 32),

            // Tombol
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pushReplacement('/seller/products'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: MamoColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lihat listing saya'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Kembali ke Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────
  Widget _bottomBar() {
    if (_step == 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_busy || _uploading) ? null : _next,
            child: (_busy)
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_step == 0
                    ? 'Lanjut'
                    : (isEdit ? 'Simpan Perubahan' : 'Kirim Listing')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 2,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              if (_step < 2) _stepper(),
              Expanded(
                child: _step == 0
                    ? _stepFoto()
                    : _step == 1
                        ? _stepInfo()
                        : _stepSukses(),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Komponen kecil ─────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

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
        child: Icon(icon, size: 20, color: const Color(0xFF0B0B0B)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0B0B0B)));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF344054)));
  }
}
