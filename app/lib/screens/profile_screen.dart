import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final verif = ref.watch(verificationStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refresh();
          ref.invalidate(verificationStatusProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kartu identitas
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: MamoColors.brandGradient,
                borderRadius: BorderRadius.circular(MamoRadius.xl),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  backgroundImage: (user?.profile?.avatar != null &&
                          user!.profile!.avatar!.isNotEmpty)
                      ? NetworkImage(user.profile!.avatar!)
                      : null,
                  child: (user?.profile?.avatar == null || user!.profile!.avatar!.isEmpty)
                      ? Text((user?.displayName ?? 'U').characters.first.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Pengguna',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(MamoRadius.pill),
                        ),
                        child: Text(
                          user?.isAdmin == true
                              ? 'Admin'
                              : user?.role == 'seller'
                                  ? 'Penjual'
                                  : 'Pembeli',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Status verifikasi mahasiswa
            verif.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final status = data['status'] as String? ?? 'none';
                final (label, color, bg, icon) = switch (status) {
                  'approved' => ('Mahasiswa terverifikasi', MamoColors.success,
                      MamoColors.successBg, Icons.verified),
                  'pending' => ('Verifikasi sedang diproses', MamoColors.primary,
                      MamoColors.infoBg, Icons.schedule),
                  'rejected' => ('Verifikasi ditolak', MamoColors.danger,
                      MamoColors.dangerBg, Icons.error_outline),
                  _ => ('Belum verifikasi mahasiswa', MamoColors.textSecondary,
                      const Color(0xFFF1F5F9), Icons.info_outline),
                };
                return InkWell(
                  onTap: () => context.push('/verification'),
                  borderRadius: BorderRadius.circular(MamoRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(MamoRadius.lg),
                    ),
                    child: Row(children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                      ),
                      Icon(Icons.chevron_right, color: color, size: 20),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Menu
            _menu(context, ref, Icons.receipt_long_outlined, 'Pesanan Saya',
                () => context.push('/orders')),
            _menu(context, ref, Icons.storefront_outlined, 'Dashboard Penjual',
                () => context.push('/seller')),
            _menu(context, ref, Icons.add_box_outlined, 'Jual Barang',
                () => context.push('/sell')),
            _menu(context, ref, Icons.favorite_border, 'Favorit',
                () => context.go('/favorites')),
            _menu(context, ref, Icons.verified_user_outlined, 'Verifikasi Mahasiswa',
                () => context.push('/verification')),
            _menu(context, ref, Icons.settings_outlined, 'Pengaturan',
                () => context.push('/settings')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, size: 18, color: MamoColors.danger),
              label: const Text('Keluar', style: TextStyle(color: MamoColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MamoColors.dangerBg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, WidgetRef ref, IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MamoRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MamoRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MamoRadius.md),
              border: Border.all(color: MamoColors.cardBorder),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: MamoColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500))),
              const Icon(Icons.chevron_right, size: 20, color: MamoColors.textMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
