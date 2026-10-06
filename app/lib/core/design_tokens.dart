import 'package:flutter/material.dart';

import 'theme.dart';

/// Token desain bersama untuk halaman auth (Login & Register).
///
/// Nilai-nilai ini diukur langsung dari screenshot desain Figma:
/// - Login    : frame 365x800
/// - Register : frame 327x713 (≈0,896x dari Login, sistem sama)
///
/// Sengaja lokal untuk halaman auth supaya tidak mengubah halaman lain
/// (Home, Product, Cart, dsb masih memakai MamoColors).
class MamoDesign {
  MamoDesign._();

  // ── Warna
  static const primary = Color(0xFF4858E8);
  static const titleDark = Color(0xFF000000);
  static const label = Color(0xFF172039);
  static const muted = Color(0xFF6D7485);
  static const icon = Color(0xFF7F8594);
  static const border = Color(0xFFE2E2E2);

  // ── Ukuran
  static const hpad = 26.0; // margin kiri/kanan konten
  static const topPad = 121.0; // jarak dari SafeArea ke label kecil
  static const fieldH = 46.0; // tinggi kotak input
  static const btnH = 46.0; // tinggi tombol utama
  static const checkSize = 16.0; // kotak checkbox
}

/// Label kecil di atas judul (mis. "SELAMAT DATANG KEMBALI").
class MamoEyebrow extends StatelessWidget {
  final String text;
  const MamoEyebrow(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: MamoDesign.primary,
        ),
      );
}

/// Judul dengan bagian berwarna: "Masuk ke " + "MAMO" (biru).
class MamoAuthTitle extends StatelessWidget {
  final String plain; // bagian hitam
  final String accent; // bagian biru
  final Key? textKey;

  const MamoAuthTitle({
    super.key,
    required this.plain,
    required this.accent,
    this.textKey,
  });

  @override
  Widget build(BuildContext context) => RichText(
        key: textKey,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: MamoDesign.titleDark,
            height: 0.95,
          ),
          children: [
            TextSpan(text: plain),
            TextSpan(text: accent, style: const TextStyle(color: MamoDesign.primary)),
          ],
        ),
      );
}

/// Label field ("Email", "Kata Sandi", ...).
class MamoFieldLabel extends StatelessWidget {
  final String text;
  const MamoFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MamoDesign.label,
          // tinggi baris dirapatkan: default Material (~16px) membuat setiap
          // label lebih tinggi dari desain dan pergeserannya menumpuk.
          height: 1.05,
        ),
      );
}

/// Kotak input: putih, border tipis #E2E2E2, radius 12, tinggi 46.
class MamoInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final double? height;
  final double fontSize;

  const MamoInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.validator,
    this.onSubmitted,
    this.height,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? MamoDesign.fieldH;
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(MamoRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    final field = TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(fontSize: fontSize, color: MamoDesign.label),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(fontSize: fontSize, color: MamoDesign.muted),
        contentPadding: EdgeInsets.symmetric(vertical: (h - 20) / 2),
        constraints: BoxConstraints(minHeight: h),
        prefixIcon: Icon(icon, size: 20, color: MamoDesign.icon),
        prefixIconConstraints: BoxConstraints(minWidth: h, maxHeight: h),
        suffixIcon: suffix,
        // M3 memberi default minWidth/minHeight 48 untuk slot ikon; tanpa
        // dibatasi, field 40/46px ikut membengkak jadi 48px.
        suffixIconConstraints: BoxConstraints(minWidth: h, maxHeight: h),
        border: b(MamoDesign.border),
        enabledBorder: b(MamoDesign.border),
        focusedBorder: b(MamoDesign.primary, 1.5),
        errorBorder: b(MamoColors.danger),
        focusedErrorBorder: b(MamoColors.danger, 1.5),
        errorStyle: const TextStyle(fontSize: 11, color: MamoColors.danger),
      ),
    );

    // Material 3 memaksa tinggi minimum 48dp lewat materialTapTargetSize
    // (default `padded`), sehingga field 40/46px ikut membengkak jadi 48px.
    // Override hanya di sekitar field auth ini supaya halaman lain tidak berubah.
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: field,
    );
  }
}

/// Ikon show/hide password — dipakai Login & Register.
///
/// Penting: IconButton bawaan Flutter punya ukuran minimum 48x48, yang akan
/// memaksa tinggi field ikut membengkak (field 40/46px jadi 48px). Karena itu
/// constraints dan padding-nya di-set eksplisit.
class MamoPasswordToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  final double size;

  const MamoPasswordToggle({
    super.key,
    required this.obscure,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: MamoDesign.icon,
        ),
        // Material 3 mengabaikan `constraints`; ukuran harus diatur lewat style,
        // kalau tidak IconButton memakai minimum 48x48 dan field ikut membengkak.
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onTap,
      );
}

/// Checkbox biru terisi dengan centang putih.
class MamoCheckbox extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const MamoCheckbox({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: MamoDesign.checkSize,
          height: MamoDesign.checkSize,
          decoration: BoxDecoration(
            color: value ? MamoDesign.primary : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: value ? MamoDesign.primary : MamoDesign.border),
          ),
          child: value
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
      );
}

/// Tombol utama biru penuh lebar.
class MamoPrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const MamoPrimaryButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MamoDesign.btnH,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: MamoDesign.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: MamoDesign.primary.withValues(alpha: 0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MamoRadius.md),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
}
