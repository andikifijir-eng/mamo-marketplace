import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Ukuran khusus halaman Register — diukur dari screenshot desain
/// (frame 327x713, sistem warna sama dengan Login).
class _R {
  _R._();
  static const hpad = 24.0;
  static const topPad = 112.0;
  static const fieldH = 40.0; // desain Register memakai input 40px
  static const btnH = 40.0;
  static const gapAfterField = 12.0; // input bawah -> label berikutnya
  static const labelGap = 5.0; // label -> input
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  /// LOGIC REGISTRASI TIDAK DIUBAH — tetap memakai authProvider.register.
  /// Satu tambahan: checkbox persetujuan wajib dicentang sebelum submit.
  Future<void> _submit() async {
    final formOk = _form.currentState!.validate();
    if (!formOk || !_agreed) {
      setState(() {}); // biar error checkbox ikut tampil
      if (!_agreed) {
        showSnack(context, 'Centang persetujuan Syarat & Ketentuan dulu', error: true);
      }
      return;
    }
    setState(() => _busy = true);
    final ok = await ref.read(authProvider.notifier).register(
          _email.text.trim(),
          _password.text,
          _name.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      showSnack(context, 'Akun berhasil dibuat. Selamat datang di MAMO!');
      context.go('/home');
    } else {
      showSnack(context, ref.read(authProvider).error ?? 'Pendaftaran gagal', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_R.hpad, _R.topPad, _R.hpad, 32),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Label kecil
                  const MamoEyebrow('BUAT AKUN BARU'),
                  const SizedBox(height: 8),

                  // ── Judul: "Daftar ke " + "MAMO"
                  const MamoAuthTitle(
                    textKey: Key('register-title'),
                    plain: 'Daftar ke ',
                    accent: 'MAMO',
                  ),
                  const SizedBox(height: 6),

                  // ── Subtitle
                  const Text(
                    'Bergabung dan mulai temukan kebutuhan Anda dalam satu aplikasi.',
                    style: TextStyle(fontSize: 12, color: MamoDesign.muted, height: 1.25),
                  ),
                  const SizedBox(height: 15),

                  // ── Nama Lengkap
                  const MamoFieldLabel('Nama Lengkap'),
                  const SizedBox(height: _R.labelGap),
                  MamoInput(
                    height: _R.fieldH,
                    fontSize: 13,
                    controller: _name,
                    hint: 'Masukkan nama lengkap',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Nama minimal 2 karakter'
                        : null,
                  ),
                  const SizedBox(height: _R.gapAfterField),

                  // ── Email
                  const MamoFieldLabel('Email'),
                  const SizedBox(height: _R.labelGap),
                  MamoInput(
                    height: _R.fieldH,
                    fontSize: 13,
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
                  const SizedBox(height: _R.gapAfterField),

                  // ── Kata Sandi
                  const MamoFieldLabel('Kata Sandi'),
                  const SizedBox(height: _R.labelGap),
                  MamoInput(
                    height: _R.fieldH,
                    fontSize: 13,
                    controller: _password,
                    hint: 'Masukkan kata sandi',
                    icon: Icons.lock_outline,
                    obscure: _obscurePass,
                    suffix: MamoPasswordToggle(
                      obscure: _obscurePass,
                      onTap: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Password minimal 8 karakter'
                        : null,
                  ),
                  const SizedBox(height: _R.gapAfterField),

                  // ── Konfirmasi Kata Sandi
                  const MamoFieldLabel('Konfirmasi Kata Sandi'),
                  const SizedBox(height: _R.labelGap),
                  MamoInput(
                    height: _R.fieldH,
                    fontSize: 13,
                    controller: _confirm,
                    hint: 'Ulangi kata sandi',
                    icon: Icons.lock_outline,
                    obscure: _obscureConfirm,
                    suffix: MamoPasswordToggle(
                      obscure: _obscureConfirm,
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Kata sandi tidak sama' : null,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 11),

                  // ── Persetujuan S&K
                  FormField<bool>(
                    key: const Key('register-agreement'),
                    initialValue: _agreed,
                    validator: (_) => _agreed ? null : 'Persetujuan wajib dicentang',
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: MamoCheckbox(
                                key: const Key('register-agreement-box'),
                                value: _agreed,
                                onTap: () {
                                  setState(() => _agreed = !_agreed);
                                  state.didChange(_agreed);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _agreed = !_agreed);
                                  state.didChange(_agreed);
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: MamoDesign.muted,
                                      height: 1.45,
                                    ),
                                    children: [
                                      TextSpan(text: 'Saya setuju dengan '),
                                      TextSpan(
                                        text: 'Syarat dan Ketentuan',
                                        style: TextStyle(
                                          color: MamoDesign.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' serta '),
                                      TextSpan(
                                        text: 'Kebijakan Privasi MAMO',
                                        style: TextStyle(
                                          color: MamoDesign.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 24),
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                  fontSize: 11, color: MamoColors.danger),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ── Tombol Daftar
                  SizedBox(
                    height: _R.btnH,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MamoDesign.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            MamoDesign.primary.withValues(alpha: 0.6),
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
                          : const Text('Daftar',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Sudah punya akun?
                  // Flexible supaya tetap aman di layar sangat sempit
                  // atau saat font sistem diperbesar.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text('Sudah punya akun? ',
                            style: TextStyle(fontSize: 12, color: MamoDesign.muted)),
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Masuk sekarang',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MamoDesign.primary),
                          ),
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
    );
  }

}
