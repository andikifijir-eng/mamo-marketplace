import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';

/// Profile screen — FINAL sesuai desain Figma image_323091.png.
///
/// Layout:
/// 1. Header solid #4858E8 (rounded bottom ~20)
///    - Avatar 64px (border putih 3px)
///    - Nama + badge bintang kuning
///    - "Akun terverifikasi" / status
///    - "4.9 dari 9 ulasan" + bintang
///    - Stats: 12 Transaksi | 4 Listing | 98% Respon chat
/// 2. Menu = individual rounded cards (white bg, border #E8EAF0, radius 14)
///    Icon di dalam rounded box #EEF0FF (40x40, radius 12)
///    Title bold + subtitle abu + ">" chevron kanan
///    Gap 8px antar card
///    - Listing saya → "4 aktif 1 pending"
///    - Favorit → "8 barang tersimpan"
///    - Pengaturan → "Privasi & notifikasi"
///    - Keamanan & Privasi → "Kontrol data dan akun"
///    - Bantuan → "Pusat bantuan MAMO"
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final verif = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Blue header ───────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF4858E8),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20, right: 20, bottom: 22,
                ),
                child: Column(
                  children: [
                    // Top bar
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
                    const SizedBox(height: 16),
                    // Avatar with white border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 32,
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
                                  color: Colors.white, fontSize: 24,
                                  fontWeight: FontWeight.w700))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Name + verification badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(user?.displayName ?? 'Nama Anda',
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                        const SizedBox(width: 6),
                        verif.maybeWhen(
                          data: (d) {
                            final s = d['status'] as String? ?? 'none';
                            if (s == 'approved') {
                              return const Icon(Icons.verified,
                                  size: 15, color: Color(0xFFEAB854));
                            }
                            return const SizedBox.shrink();
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Verification status text
                    verif.maybeWhen(
                      data: (d) {
                        final s = d['status'] as String? ?? 'none';
                        final label = switch (s) {
                          'approved' => 'Akun terverifikasi',
                          'pending' => 'Verifikasi sedang diproses',
                          'rejected' => 'Verifikasi ditolak',
                          _ => 'Belum terverifikasi',
                        };
                        return Text(label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75)));
                      },
                      orElse: () => Text('Belum terverifikasi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75))),
                    ),
                    const SizedBox(height: 8),
                    // Rating stars + "4.9 dari 9 ulasan"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFEAB854)),
                        const SizedBox(width: 4),
                        Text('4.9 dari 9 ulasan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('12', 'Transaksi'),
                        _divider(),
                        _stat('4', 'Listing'),
                        _divider(),
                        _stat('98%', 'Respon chat'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Menu cards ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _menuCard(
                      icon: Icons.storefront_outlined,
                      title: 'Listing saya',
                      subtitle: '4 aktif 1 pending',
                      onTap: () => context.push('/seller/products'),
                    ),
                    const SizedBox(height: 8),
                    _menuCard(
                      icon: Icons.favorite_border,
                      title: 'Favorit',
                      subtitle: '8 barang tersimpan',
                      onTap: () => context.go('/favorites'),
                    ),
                    const SizedBox(height: 8),
                    _menuCard(
                      icon: Icons.settings_outlined,
                      title: 'Pengaturan',
                      subtitle: 'Privasi & notifikasi',
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 8),
                    _menuCard(
                      icon: Icons.lock_outline,
                      title: 'Keamanan & Privasi',
                      subtitle: 'Kontrol data dan akun',
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 8),
                    _menuCard(
                      icon: Icons.help_outline,
                      title: 'Bantuan',
                      subtitle: 'Pusat bantuan MAMO',
                      onTap: () {},
                    ),
                  ],
                ),
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
              fontSize: 15, fontWeight: FontWeight.w800,
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
      width: 1, height: 24,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF4858E8)),
            ),
            const SizedBox(width: 12),
            // Title + subtitle
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
                        fontSize: 12, color: Color(0xFF737373))),
                ],
              ),
            ),
            // Chevron
            const Icon(Icons.chevron_right,
                size: 20, color: Color(0xFFB5B9C1)),
          ],
        ),
      ),
    );
  }
}
