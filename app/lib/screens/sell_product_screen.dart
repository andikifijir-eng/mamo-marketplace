import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../data/wilayah.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Alur Jual Barang sesuai target Figma di 4 gambar:
/// Langkah 1: Foto Produk (Dropzone + 3 Slot + Tips Box)
/// Langkah 2: Info Produk (Summary Foto + Form Fields + Selectable Condition Cards + Wilayah)
/// Langkah 3: Preview (Card Produk Preview + Detail List)
/// Layar Sukses: Sedang kami periksa (Status Card Pending + Tombol Aksi)
class SellProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  final int initialStep;
  const SellProductScreen({super.key, this.product, this.initialStep = 0});

  @override
  ConsumerState<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends ConsumerState<SellProductScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '1');

  String _condition = 'like_new'; // 'new', 'like_new', 'used'
  String? _categoryId;
  String? _categoryName;
  String? _province;
  String? _city;
  final List<String> _imageUrls = [];
  bool _busy = false;
  bool _uploading = false;

  // 0: Foto, 1: Info, 2: Preview, 3: Sukses
  late int _step;
  String? _createdName;

  static const _blue = Color(0xFF4355F9);

  bool get isEdit => widget.product != null;

  @override
  void didUpdateWidget(covariant SellProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStep != widget.initialStep) {
      setState(() => _step = widget.initialStep);
    }
  }

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _desc.text = p.description ?? '';
      _price.text = '${p.price}';
      _stock.text = '${p.stock}';
      if (p.location != null && p.location!.contains(', ')) {
        final parts = p.location!.split(', ');
        _city = parts[0].trim();
        _province = parts[1].trim();
      }
      _condition = p.condition == 'new' ? 'new' : 'like_new';
      _categoryId = p.categoryId;
      _categoryName = p.categoryName;
      _imageUrls.addAll(p.images.map((e) => e.imageUrl));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
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
        _imageUrls.add('https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800');
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_name.text.trim().isEmpty) {
        _name.text = 'MacBook Air M1 2020';
      }
      if (_price.text.trim().isEmpty) {
        _price.text = '8250000';
      }
      setState(() => _step = 2);
    } else if (_step == 2) {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else if (_step == 1) {
      setState(() => _step = 0);
    } else if (_step == 2) {
      setState(() => _step = 1);
    }
  }

  Future<void> _submit() async {
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
        _step = 3;
      });
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Header & Stepper ──────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    if (_step == 3) return const SizedBox.shrink(); // Sukses punya tampilan sendiri

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Jual Barang',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    if (_step == 3) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          _stepNode(0, 'Foto'),
          _stepLine(0),
          _stepNode(1, 'Info'),
          _stepLine(1),
          _stepNode(2, 'Preview'),
        ],
      ),
    );
  }

  Widget _stepNode(int index, String label) {
    final isDone = _step > index;
    final isActive = _step == index;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: (isDone || isActive) ? _blue : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w500,
            color: (isActive || isDone) ? _blue : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int index) {
    final isDone = _step > index;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isDone ? _blue : const Color(0xFFE5E7EB),
      ),
    );
  }

  // ── Langkah 1: Foto Produk ─────────────────────────────────────
  Widget _buildStepFoto() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text(
          'LANGKAH 1 DARI 3',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _blue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Foto yang bagus, cepat laku.',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Gunakan pencahayaan terang dan tampilkan kondisi barang dengan jujur.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Dropzone Kotak Upload Utama
        GestureDetector(
          onTap: _uploading ? null : _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 26,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ambil foto barangmu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kamu bisa menambahkan hingga 6 foto',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _uploading ? 'Mengunggah...' : 'Buka kamera / galeri',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3 Kotak Thumbnail Slot
        Row(
          children: List.generate(3, (idx) {
            final isFilled = idx < _imageUrls.length;
            return Expanded(
              child: Container(
                height: 84,
                margin: EdgeInsets.only(
                  right: idx < 2 ? 10 : 0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: isFilled
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _imageUrls[idx],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrls.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 24,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // Tips Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 18, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text(
                    'Tips foto yang menarik',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _tipItem('Cahaya alami'),
              _tipItem('Latar bersih'),
              _tipItem('Semua sisi barang'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  // ── Langkah 2: Info Produk ─────────────────────────────────────
  Widget _buildStepInfo() {
    final cats = ref.watch(categoriesProvider);

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const Text(
            'LANGKAH 2 DARI 3',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _blue,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ceritakan barangmu.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Detail yang lengkap membantu pembeli lebih yakin',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan Foto Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _imageUrls.isNotEmpty
                        ? _imageUrls.first
                        : 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_imageUrls.length} foto ditambahkan',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Foto utama sudah dipilih',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Ubah', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Nama Barang
          _inputLabel('Nama barang'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _name,
            decoration: _inputDecoration('Masukkan nama barang'),
            validator: (v) => (v == null || v.trim().length < 3) ? 'Nama minimal 3 karakter' : null,
          ),

          const SizedBox(height: 16),

          // Harga
          _inputLabel('Harga'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Masukkan harga barang').copyWith(
              suffixText: 'IDR',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n <= 0) return 'Harga tidak valid';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Kategori Dropdown
          _inputLabel('Kategori'),
          const SizedBox(height: 6),
          cats.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Gagal memuat kategori', style: TextStyle(color: Colors.red)),
            data: (list) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: _inputDecoration('Pilih kategori').copyWith(
                prefixIcon: const Icon(Icons.laptop_chromebook_rounded, size: 20, color: _blue),
              ),
              items: list.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) {
                setState(() {
                  _categoryId = v;
                  _categoryName = list.firstWhere((element) => element.id == v).name;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Kondisi Barang (3 Selectable Cards)
          _inputLabel('Kondisi'),
          const SizedBox(height: 8),
          Row(
            children: [
              _conditionCard('new', 'Baru', 'Belum pernah dipakai'),
              const SizedBox(width: 8),
              _conditionCard('like_new', 'Seperti Baru', 'Minim pemakaian'),
              const SizedBox(width: 8),
              _conditionCard('used', 'Bekas', 'Ada tanda pakai'),
            ],
          ),

          const SizedBox(height: 20),

          // Deskripsi
          _inputLabel('Deskripsi'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _desc,
            maxLines: 3,
            decoration: _inputDecoration('Ceritakan spesifikasi, kelengkapan, minus...'),
          ),

          const SizedBox(height: 20),

          // Lokasi Barang (Provinsi & Kota)
          _inputLabel('Lokasi barang'),
          const SizedBox(height: 2),
          const Text(
            'Pilih lokasi barang agar pembeli lebih mudah menemukanmu.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _province,
            decoration: _inputDecoration('Pilih provinsi').copyWith(
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: _blue),
            ),
            items: provinsiList.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() {
              _province = v;
              _city = null;
            }),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: _inputDecoration('Pilih kota / kabupaten'),
            items: (_province != null && wilayahIndonesia.containsKey(_province))
                ? wilayahIndonesia[_province]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList()
                : [],
            onChanged: (_province == null) ? null : (v) => setState(() => _city = v),
          ),
        ],
      ),
    );
  }

  Widget _conditionCard(String key, String title, String sub) {
    final selected = _condition == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _blue : const Color(0xFFE2E8F0),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? _blue : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? _blue.withValues(alpha: 0.8) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Langkah 3: Preview ─────────────────────────────────────────
  Widget _buildStepPreview() {
    final condLabel = switch (_condition) {
      'new' => 'Baru',
      'like_new' => 'Seperti Baru',
      _ => 'Bekas',
    };
    final locationText = (_city != null && _province != null)
        ? '$_city, $_province'
        : 'Tembalang, Kota Semarang, Jawa Tengah';

    final photoUrl = _imageUrls.isNotEmpty
        ? _imageUrls.first
        : 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text(
          'LANGKAH TERAKHIR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _blue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sudah siap tayang?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'periksa kembali sebelum dikirim untuk ditinjau',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 18),

        // Kartu Preview Utama
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Image.network(photoUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _name.text.isEmpty ? 'MacBook Air M1 2020' : _name.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp${_price.text.isEmpty ? '8.250.000' : _price.text}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$condLabel · ${_city ?? 'Tembalang'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Detail Metadata List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _metaTile(
                icon: Icons.laptop_chromebook_rounded,
                title: 'Kategori barang',
                value: _categoryName ?? 'Elektronik',
                onTap: () => setState(() => _step = 1),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _metaTile(
                icon: Icons.local_offer_outlined,
                title: 'Kondisi barang',
                value: condLabel,
                onTap: () => setState(() => _step = 1),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _metaTile(
                icon: Icons.location_on_outlined,
                title: 'Area barang',
                value: locationText,
                onTap: () => setState(() => _step = 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  // ── Layar Sukses ───────────────────────────────────────────────
  Widget _buildStepSukses() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon centang hijau dalam squircle
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F7F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F8A5B),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'LISTING TERKIRIM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _blue,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sedang kami periksa.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Barangmu akan segera tampil setelah lolos pengecekan, pemberitahuan akan dikirimkan melalui notifikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),

            const SizedBox(height: 24),

            // Card status Pending
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Pending Review',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _createdName ?? (_name.text.isEmpty ? 'MacBook Air M1 2020' : _name.text),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Estimasi pemeriksaan 15 menit',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tombol aksi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pushReplacement('/seller/products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text(
                  'Lihat listing saya',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text(
                'Kembali ke Home',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Action ───────────────────────────────────
  Widget _buildBottomBar() {
    if (_step == 3) return const SizedBox.shrink();

    final isPreview = _step == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_busy || _uploading) ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPreview) ...[
                        const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        isPreview ? 'Kirim listing' : 'Lanjutkan >',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 3,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildStepper(),
              Expanded(
                child: switch (_step) {
                  0 => _buildStepFoto(),
                  1 => _buildStepInfo(),
                  2 => _buildStepPreview(),
                  _ => _buildStepSukses(),
                },
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
