import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Warna khusus halaman Login, diambil langsung dari screenshot desain Figma
/// (frame 365x800). Sengaja lokal, bukan MamoColors, supaya perubahan di sini
/// tidak ikut mengubah halaman lain.
class _C {
  _C._();
  static const primary = Color(0xFF4858E8);
  static const titleDark = Color(0xFF000000);
  static const label = Color(0xFF172039);
  static const muted = Color(0xFF6D7485);
  static const icon = Color(0xFF7F8594);
  static const border = Color(0xFFE2E2E2);
}

/// Ukuran yang diambil dari screenshot (px desain == dp).
class _S {
  _S._();
  static const hpad = 26.0; // margin kiri/kanan konten
  static const topPad = 121.0; // + SafeArea (label kecil di y≈124 pada frame desain)
  static const fieldH = 46.0; // tinggi kotak input
  static const btnH = 46.0; // tinggi tombol Masuk
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// LOGIC TIDAK DIUBAH — validasi, provider, navigasi tetap sama.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      context.go('/home');
    } else {
      showSnack(context, ref.read(authProvider).error ?? 'Login gagal', error: true);
    }
  }

  /// Fitur tambahan yang sudah ada (tidak tampak di screenshot) — dipertahankan.
  Future<void> _forgot() async {
    final ctrl = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Lupa Password'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Email terdaftar'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Kirim')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(authRepoProvider).forgotPassword(email);
      if (mounted) {
        showSnack(context, 'Link reset password dikirim. Cek email kamu.');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Gagal mengirim permintaan reset', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_S.hpad, _S.topPad, _S.hpad, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - _S.topPad - 32,
              ),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Label kecil
                    const Text(
                      'SELAMAT DATANG KEMBALI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _C.primary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Judul: "Masuk ke " hitam + "MAMO" biru
                    RichText(
                      key: const Key('login-title'),
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _C.titleDark,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: 'Masuk ke '),
                          TextSpan(text: 'MAMO', style: TextStyle(color: _C.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    // ── Subtitle
                    const Text(
                      'Lanjutkan menemukan barang di sekitarmu.',
                      style: TextStyle(fontSize: 12, color: _C.muted, height: 1.4),
                    ),
                    const SizedBox(height: 29),

                    // ── Email
                    const _FieldLabel('Email'),
                    const SizedBox(height: 5),
                    _input(
                      controller: _email,
                      hint: 'Masukkan email',
                      icon: Icons.mail_outline,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 11),

                    // ── Kata Sandi
                    const _FieldLabel('Kata Sandi'),
                    const SizedBox(height: 6),
                    _input(
                      controller: _password,
                      hint: 'Masukkan kata sandi',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: _C.icon,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),

                    // ── Ingat saya  +  Lupa kata sandi?
                    Row(
                      children: [
                        _checkBox(),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: const Text('Ingat saya',
                              style: TextStyle(fontSize: 13, color: _C.muted)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _forgot,
                          child: const Text(
                            'Lupa kata sandi?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 21),

                    // ── Tombol Masuk
                    SizedBox(
                      height: _S.btnH,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _C.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(MamoRadius.md),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Masuk',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Belum punya akun?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? ',
                            style: TextStyle(fontSize: 13, color: _C.muted)),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: const Text(
                            'Daftar sekarang',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _C.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kotak input: putih, border tipis #E2E2E2, radius 12, tinggi 46.
  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    Widget? suffix,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(MamoRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 14, color: _C.label),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _C.muted),
        contentPadding: const EdgeInsets.symmetric(vertical: 12.5),
        constraints: const BoxConstraints(minHeight: _S.fieldH),
        prefixIcon: Icon(icon, size: 20, color: _C.icon),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        suffixIcon: suffix,
        border: b(_C.border),
        enabledBorder: b(_C.border),
        focusedBorder: b(_C.primary, 1.5),
        errorBorder: b(MamoColors.danger),
        focusedErrorBorder: b(MamoColors.danger, 1.5),
        errorStyle: const TextStyle(fontSize: 11, color: MamoColors.danger),
      ),
    );
  }

  /// Checkbox "Ingat saya" — biru terisi dengan centang putih.
  Widget _checkBox() {
    return GestureDetector(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _rememberMe ? _C.primary : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _rememberMe ? _C.primary : _C.border),
        ),
        child: _rememberMe ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.label),
      );
}
