import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

/// Profile screen sesuai desain Figma:
/// Header biru gradient + avatar + nama + badge verifikasi
/// Stats: rating, transaksi, listing, respon chat
/// Menu: Listing saya, Favorit, Pengaturan, Keamanan & Privasi, Bantuan
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final verif = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header biru gradient ─────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4858E8), Color(0xFF5B69EA)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Top bar: title + settings icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profil',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings_outlined,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Avatar + name + verification
                  Row(
                    children: [
                      CircleAvatar(
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(user?.displayName ?? 'Nama Anda',
                                      style: const TextStyle(
                                        fontSize: 17, fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                ),
                                const SizedBox(width: 6),
                                // Verification badge
                                verif.maybeWhen(
                                  data: (d) {
                                    final s = d['status'] as String? ?? 'none';
                                    if (s == 'approved') {
                                      return const Icon(Icons.verified,
                                          size: 18, color: Color(0xFFEAB854));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  orElse: () => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _Stat(value: '4.9', label: 'Rating'),
                      _Stat(value: '12', label: 'Transaksi'),
                      _Stat(value: '4', label: 'Listing'),
                      _Stat(value: '98%', label: 'Respon'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Menu items ────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  // Verification status banner
                  verif.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (data) {
                      final status = data['status'] as String? ?? 'none';
                      if (status == 'approved') return const SizedBox.shrink();
                      final (label, color, bg, icon) = switch (status) {
                        'pending' => (
                          'Verifikasi sedang diproses',
                          MamoColors.primary,
                          const Color(0xFFEEF0FF),
                          Icons.schedule
                        ),
                        'rejected' => (
                          'Verifikasi ditolak',
                          MamoColors.danger,
                          const Color(0xFFFFF0F0),
                          Icons.error_outline
                        ),
                        _ => (
                          'Belum verifikasi mahasiswa',
                          const Color(0xFF6B7280),
                          const Color(0xFFF1F5F9),
                          Icons.info_outline
                        ),
                      };
                      return _MenuCard(
                        icon: icon,
                        iconColor: color,
                        iconBg: bg,
                        title: label,
                        subtitle: 'Ketuk untuk verifikasi',
                        onTap: () => context.push('/verification'),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.storefront_outlined,
                    title: 'Listing Saya',
                    subtitle: 'Kelola produk yang kamu jual',
                    onTap: () => context.push('/seller/products'),
                  ),
                  _MenuCard(
                    icon: Icons.favorite_border,
                    title: 'Favorit',
                    subtitle: 'Barang yang kamu simpan',
                    onTap: () => context.go('/favorites'),
                  ),
                  _MenuCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Pesanan Saya',
                    subtitle: 'Riwayat transaksi',
                    onTap: () => context.push('/orders'),
                  ),
                  _MenuCard(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    subtitle: 'Notifikasi & privasi',
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuCard(
                    icon: Icons.lock_outline,
                    title: 'Keamanan & Privasi',
                    subtitle: 'Kontrol data dan akun',
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuCard(
                    icon: Icons.help_outline,
                    title: 'Bantuan',
                    subtitle: 'Hubungi bantuan MAMO',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  // Logout
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: MamoColors.danger, size: 20),
                      title: const Text('Keluar dari akun',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: MamoColors.danger)),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: MamoColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
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
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    this.iconColor,
    this.iconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: iconBg ?? const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 20,
              color: iconColor ?? const Color(0xFF4858E8)),
        ),
        title: Text(title,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: Color(0xFF172039))),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(
                  fontSize: 12, color: Color(0xFF999DA8)))
            : null,
        trailing: const Icon(Icons.chevron_right,
            size: 20, color: Color(0xFFBEC2C8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}
