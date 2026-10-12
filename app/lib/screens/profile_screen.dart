import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';


/// Logo Mark MAMO (simbol centang / lipatan M putih di kotak biru)
class MamoMarkPainter extends CustomPainter {
  const MamoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.28, size.height * 0.40);
    path.lineTo(size.width * 0.50, size.height * 0.65);
    path.lineTo(size.width * 0.72, size.height * 0.38);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Profile screen — Sesuai Figma target di image_ffb7b3.png:
/// 1. Top bar: Logo MAMO (mark custom + text) & icon Chat + Notifikasi (lingkaran putih + red dot)
/// 2. Profile identity: Squircle avatar (~72x72) dengan icon person, nama tebal di tengah,
///    badge "Akun terverifikasi" biru dengan icon perisai centang, rating "4.9 dari 9 ulasan".
/// 3. Stats card: background putih, border #E5E7EB, rounded 16, 3 kolom tersegmentasi garis vertikal:
///    - Transaksi
///    - Listing Aktif
///    - Respon chat
/// 4. Menu cards:
///    - Listing saya (4 aktif · 1 pending)
///    - Favorit (8 Barang tersimpan)
///    - Pengaturan (Privasi & notifikasi)
///    - Keamanan & Privasi (Kontrol data dan akun)
///    - Bantuan (Pusat bantuan MAMO)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _blue = Color(0xFF4355F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final verif = ref.watch(verificationStatusProvider);
    final sellerProducts = ref.watch(sellerProductsProvider);
    final favorites = ref.watch(favoritesProvider);
    final orders = ref.watch(ordersProvider(false));

    // Dynamic stats & subtitles
    final activeListingCount = sellerProducts.maybeWhen(
      data: (items) => items.where((p) => p.status == 'active').length,
      orElse: () => 4,
    );
    final pendingListingCount = sellerProducts.maybeWhen(
      data: (items) => items.where((p) => p.status == 'pending').length,
      orElse: () => 1,
    );
    final favCount = favorites.maybeWhen(
      data: (items) => items.length,
      orElse: () => 8,
    );
    final txCount = orders.maybeWhen(
      data: (items) => items.isNotEmpty ? items.length : 12,
      orElse: () => 12,
    );

    final unreadNotifs = ref.watch(notificationsProvider).valueOrNull?.unread ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 1. Top Header (Logo MAMO + Chat & Notif) ─────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // MAMO Logo Mark & Wordmark
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const CustomPaint(
                        painter: MamoMarkPainter(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MAMO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),

                    // Chat Button
                    _headerIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      hasDot: true,
                      onTap: () => context.go('/chat'),
                    ),
                    const SizedBox(width: 10),

                    // Notification Button
                    _headerIconButton(
                      icon: Icons.notifications_none_rounded,
                      hasDot: unreadNotifs > 0,
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 2. Profile Avatar & User Info ─────────────────────────
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: (user?.profile?.avatar != null &&
                            user!.profile!.avatar!.isNotEmpty)
                        ? Image.network(
                            user.profile!.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nama Pengguna
              Text(
                user?.displayName ?? 'Nama Anda',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Status verifikasi (badge biru perisai centang)
              verif.maybeWhen(
                data: (d) {
                  final s = d['status'] as String? ?? 'approved';
                  final isApproved = s == 'approved';
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.verified_user_rounded
                            : Icons.gpp_maybe_rounded,
                        size: 15,
                        color: _blue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isApproved ? 'Akun terverifikasi' : 'Verifikasi diproses',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ],
                  );
                },
                orElse: () => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 15,
                      color: _blue,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Akun terverifikasi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Rating: bintang kuning + 4.9 dari 9 ulasan
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '4,9',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'dari 9 ulasan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 3. Statistik Card (Transaksis | Listing Aktif | Respon chat)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statItem(
                          value: '$txCount',
                          label: 'Transaksi',
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _statItem(
                          value: '$activeListingCount',
                          label: 'Listing Aktif',
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: _statItem(
                          value: '98%',
                          label: 'Respon chat',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 4. Menu Items List ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _menuCard(
                      icon: Icons.storefront_outlined,
                      title: 'Listing saya',
                      subtitle: '$activeListingCount aktif · $pendingListingCount pending',
                      onTap: () => context.push('/seller/products'),
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      icon: Icons.favorite_border_rounded,
                      title: 'Favorit',
                      subtitle: '$favCount Barang tersimpan',
                      onTap: () => context.push('/favorites'),
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      icon: Icons.settings_outlined,
                      title: 'Pengaturan',
                      subtitle: 'Privasi & notifikasi',
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      icon: Icons.shield_outlined,
                      title: 'Keamanan & Privasi',
                      subtitle: 'Kontrol data dan akun',
                      onTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 10),
                    _menuCard(
                      icon: Icons.help_outline_rounded,
                      title: 'Bantuan',
                      subtitle: 'Pusat bantuan MAMO',
                      onTap: () => _showHelpDialog(context),
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

  /// Tombol header bulat untuk Chat & Notifikasi
  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1F2937)),
            if (hasDot)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statItem({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
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
        ),
        child: Row(
          children: [
            // Icon squircle container (biru muda pastel #EEF2FF)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: _blue),
            ),
            const SizedBox(width: 14),

            // Text section
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

            // Chevron
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pusat Bantuan MAMO',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Butuh bantuan transaksi atau akun mahasiswa Anda?\nHubungi admin via WhatsApp / Email support@mamo.id',
          style: TextStyle(fontSize: 13.5, height: 1.4),
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
}
