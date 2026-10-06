import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

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
            padding: const EdgeInsets.fromLTRB(
                MamoDesign.hpad, MamoDesign.topPad, MamoDesign.hpad, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - MamoDesign.topPad - 32,
              ),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Label kecil
                    const MamoEyebrow('SELAMAT DATANG KEMBALI'),
                    const SizedBox(height: 10),

                    // ── Judul: "Masuk ke " + "MAMO"
                    const MamoAuthTitle(
                      textKey: Key('login-title'),
                      plain: 'Masuk ke ',
                      accent: 'MAMO',
                    ),
                    const SizedBox(height: 2),

                    // ── Subtitle
                    const Text(
                      'Lanjutkan menemukan barang di sekitarmu.',
                      style: TextStyle(fontSize: 12, color: MamoDesign.muted, height: 1.4),
                    ),
                    const SizedBox(height: 29),

                    // ── Email
                    const MamoFieldLabel('Email'),
                    const SizedBox(height: 5),
                    MamoInput(
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
                    const MamoFieldLabel('Kata Sandi'),
                    const SizedBox(height: 6),
                    MamoInput(
                      controller: _password,
                      hint: 'Masukkan kata sandi',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: MamoPasswordToggle(
                        obscure: _obscure,
                        onTap: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),

                    // ── Ingat saya  +  Lupa kata sandi?
                    Row(
                      children: [
                        MamoCheckbox(
                          value: _rememberMe,
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: const Text('Ingat saya',
                              style: TextStyle(fontSize: 13, color: MamoDesign.muted)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _forgot,
                          child: const Text(
                            'Lupa kata sandi?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MamoDesign.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 21),

                    // ── Tombol Masuk
                    MamoPrimaryButton(label: 'Masuk', busy: _busy, onPressed: _submit),
                    const SizedBox(height: 22),

                    // ── Belum punya akun?
                    // Flexible supaya aman di layar sempit / font besar.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text('Belum punya akun? ',
                              style: TextStyle(fontSize: 13, color: MamoDesign.muted)),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text(
                              'Daftar sekarang',
                              style: TextStyle(
                                  fontSize: 13,
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
      ),
    );
  }
}
