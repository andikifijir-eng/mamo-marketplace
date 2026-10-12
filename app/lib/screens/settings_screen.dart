import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../widgets/common.dart';

/// Screen "Pengaturan" sesuai target desain di image_340020.png:
/// 1. Header: Tombol back bulat (border abu tipis) + Judul "Pengaturan" bold.
/// 2. Section "AKUN":
///    - Card putih dengan border abu tipis (#E5E7EB), rounded 16:
///      * "Informasi profil" | Sub: "Nama, email, dan nomor telepon" | Chevron kanan
///      * Divider abu tipis
///      * "Verifikasi akun" | Sub: "Status terverifikasi" | Badge pill hijau muda "Aktif"
/// 3. Section "PREFERENSI":
///    - Card putih dengan border abu tipis (#E5E7EB), rounded 16:
///      * "Notifikasi" | Sub: "Pesan, penawaran, dan listing" | Switch toggle (biru)
///      * Divider abu tipis
///      * "Privasi" | Sub: "Atur siapa yang bisa melihat profilmu" | Chevron kanan
///      * Divider abu tipis
///      * "Ajukan penghapusan akun" | Sub: "Penghapusan akun secara permanen" | Chevron kanan
/// 4. Tombol Logout:
///    - Card merah muda sangat pudar (#FFF0F0), rounded 16.
///    - Icon pintu keluar / logout merah, teks merah bold "Keluar dari akun".
/// 5. Tidak ada icon leading di dalam item list section.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifEnabled = true;

  static const _blue = Color(0xFF4355F9);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final verif = ref.watch(verificationStatusProvider);

    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    final isVerified = verif.maybeWhen(
      data: (d) => (d['status'] as String? ?? 'approved') == 'approved',
      orElse: () => true,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Header (Tombol back bulat + Judul) ──────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (canPop) {
                        router!.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
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
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Content ListView ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Section AKUN
                  _sectionLabel('AKUN'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardBoxDecoration(),
                    child: Column(
                      children: [
                        _simpleListItem(
                          title: 'Informasi profil',
                          subtitle: 'Nama, email, dan nomor telepon',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: Color(0xFF9CA3AF),
                          ),
                          onTap: () => _showProfileDialog(context, user),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _simpleListItem(
                          title: 'Verifikasi akun',
                          subtitle: 'Status terverifikasi',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: Color(0xFF15803D),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVerified ? 'Aktif' : 'Diproses',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => context.push('/verification'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section PREFERENSI
                  _sectionLabel('PREFERENSI'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardBoxDecoration(),
                    child: Column(
                      children: [
                        _simpleListItem(
                          title: 'Notifikasi',
                          subtitle: 'Pesan, penawaran, dan listing',
                          trailing: Switch(
                            value: _notifEnabled,
                            activeTrackColor: _blue,
                            onChanged: (val) =>
                                setState(() => _notifEnabled = val),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _simpleListItem(
                          title: 'Privasi',
                          subtitle: 'Atur siapa yang bisa melihat profilmu',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: Color(0xFF9CA3AF),
                          ),
                          onTap: () => showSnack(
                              context, 'Profil kamu saat ini berstatus publik'),
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _simpleListItem(
                          title: 'Ajukan penghapusan akun',
                          subtitle: 'Penghapusan akun secara permanen',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: Color(0xFF9CA3AF),
                          ),
                          onTap: () => _showDeleteConfirm(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 3. Tombol Logout (Card Merah Muda / Pink) ────────
                  GestureDetector(
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 21,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Keluar dari akun',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.015),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _simpleListItem({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Informasi Profil',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${user?.displayName ?? "-"}',
                style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 6),
            Text('Email: ${user?.email ?? "-"}',
                style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 6),
            Text('No HP: ${user?.profile?.phone ?? "Belum diatur"}',
                style: const TextStyle(fontSize: 13.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup',
                style: TextStyle(color: _blue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus akun?'),
        content: const Text(
          'Akun dan semua data akan dihapus permanen. Aksi ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              showSnack(context, 'Permintaan penghapusan akun telah dicatat.');
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
