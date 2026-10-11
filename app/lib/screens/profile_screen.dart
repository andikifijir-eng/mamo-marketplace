import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';

/// Profile screen — FINAL sesuai desain Figma image_3482e2.png (phone kanan).
///
/// Layout (top → bottom):
/// 1. Header solid #4858E8, NO rounded bottom (hard edge ke #EEF0FF)
///    - Row: "Profil" (kiri) + gear icon (kanan)
///    - CircleAvatar 72px, bg white24
///    - Nama + badge verifikasi (bintang kuning #EAB854 jika approved)
///    - "Belum terverifikasi" / status verifikasi (white70, 12px)
///    - Stats: 4.9 | 12 | 4 | 98% dengan label Rating/Transaksi/Listing/Respon
///      Divider vertikal white20 1px×28
/// 2. Menu bg #EEF0FF, separator #E9EBF3 (1px, margin horizontal 56px)
///    - Listing saya → "Aktif - 1 pending"
///    - Favorit → "8 barang tersimpan"
///    - Pesanan → "Riwayat transaksi"
///    - Pengaturan → "Privasi & notifikasi"
///    - Keamanan & Privasi → "Kontrol data dan akun"
///    - Bantuan → "Pusat bantuan MAMO"
///    (TIDAK ada tombol Keluar di profile — ada di Settings)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final verif = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0FF),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Blue header (solid, hard edge) ────────────────────
              Container(
                width: double.infinity,
                color: const Color(0xFF4858E8),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20, right: 20, bottom: 24,
                ),
                child: Column(
                  children: [
                    // Top bar: "Profil" + settings gear
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Profil',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: const Icon(Icons.settings_outlined,
                              size: 22, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white24,
                      backgroundImage: (user?.profile?.avatar != null &&
                              user!.profile!.avatar!.isNotEmpty)
                          ? NetworkImage(user.profile!.avatar!)
                          : null,
                      child: (user?.profile?.avatar == null ||
                              user!.profile!.avatar!.isEmpty)
                          ? Text(
                              (user?.displayName ?? 'U')
                                  .characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 28,
                                fontWeight: FontWeight.w700))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Name + verification badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(user?.displayName ?? 'Nama Anda',
                            style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        const SizedBox(width: 6),
                        verif.maybeWhen(
                          data: (d) {
                            final s = d['status'] as String? ?? 'none';
                            if (s == 'approved') {
                              return const Icon(Icons.verified,
                                  size: 16, color: Color(0xFFEAB854));
                            }
                            return const SizedBox.shrink();
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Verification status text
                    verif.maybeWhen(
                      data: (d) {
                        final s = d['status'] as String? ?? 'none';
                        final label = switch (s) {
                          'approved' => 'Mahasiswa terverifikasi',
                          'pending' => 'Verifikasi sedang diproses',
                          'rejected' => 'Verifikasi ditolak',
                          _ => 'Belum terverifikasi',
                        };
                        return Text(label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7)));
                      },
                      orElse: () => Text('Belum terverifikasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7))),
                    ),
                    const SizedBox(height: 16),
                    // Stats: Rating | Transaksi | Listing | Respon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('4.9', 'Rating'),
                        _divider(),
                        _stat('12', 'Transaksi'),
                        _divider(),
                        _stat('4', 'Listing'),
                        _divider(),
                        _stat('98%', 'Respon'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Menu list (bg #EEF0FF) ─────────────────────────────
              Column(
                children: [
                  _menuRow(
                    icon: Icons.storefront_outlined,
                    title: 'Listing saya',
                    subtitle: 'Aktif - 1 pending',
                    onTap: () => context.push('/seller/products'),
                  ),
                  _separator(),
                  _menuRow(
                    icon: Icons.favorite_border,
                    title: 'Favorit',
                    subtitle: '8 barang tersimpan',
                    onTap: () => context.go('/favorites'),
                  ),
                  _separator(),
                  _menuRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'Pesanan',
                    subtitle: 'Riwayat transaksi',
                    onTap: () => context.push('/orders'),
                  ),
                  _separator(),
                  _menuRow(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    subtitle: 'Privasi & notifikasi',
                    onTap: () => context.push('/settings'),
                  ),
                  _separator(),
                  _menuRow(
                    icon: Icons.lock_outline,
                    title: 'Keamanan & Privasi',
                    subtitle: 'Kontrol data dan akun',
                    onTap: () => context.push('/settings'),
                  ),
                  _separator(),
                  _menuRow(
                    icon: Icons.help_outline,
                    title: 'Bantuan',
                    subtitle: 'Pusat bantuan MAMO',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1, height: 28,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFEEF0FF),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF4858E8)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Color(0xFF172039))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6E7383))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: Color(0xFFB6B9C2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _separator() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56, right: 20),
      color: const Color(0xFFE9EBF3),
    );
  }
}
