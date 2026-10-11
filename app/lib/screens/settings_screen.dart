import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Pengaturan sesuai desain Figma:
/// AKUN: Informasi profil, Verifikasi akun
/// PREFERENSI: Notifikasi, Privasi
/// KEAMANAN: Ajukan penghapusan akun, Keluar
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  bool _loaded = false;
  bool _busy = false;
  bool _notifEnabled = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(userRepoProvider).updateProfile(
            fullName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          );
      await ref.read(authProvider.notifier).refresh();
      if (mounted) showSnack(context, 'Profil disimpan');
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (!_loaded && user != null) {
      _name.text = user.profile?.fullName ?? '';
      _phone.text = user.profile?.phone ?? '';
      _bio.text = user.profile?.bio ?? '';
      _loaded = true;
    }

    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBEC2C8)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Color(0xFF0B0B0B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Pengaturan',
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: Color(0xFF0B0B0B))),
                ],
              ),
            ),
            // ── Content ────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // AKUN section
                  _sectionLabel('AKUN'),
                  const SizedBox(height: 8),
                  // Informasi profil — expandable
                  Container(
                    decoration: _cardDecoration(),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: _iconBox(Icons.person_outline),
                      title: const Text('Informasi profil',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Nama, email dan nomor telepon',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999DA8))),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. HP',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bio,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            hintText: 'Ceritakan sedikit tentang kamu',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Email: ${user?.email ?? '-'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: MamoColors.textSecondary)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _save,
                            child: _busy
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan Perubahan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _menuItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Verifikasi akun',
                    subtitle: 'Status terverifikasi mahasiswa',
                    onTap: () => context.push('/verification'),
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('PREFERENSI'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: _cardDecoration(),
                    child: SwitchListTile(
                      secondary: _iconBox(Icons.notifications_outlined),
                      title: const Text('Notifikasi',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Pesan, pengumuman, dan listing',
                          style: TextStyle(fontSize: 12, color: Color(0xFF999DA8))),
                      value: _notifEnabled,
                      activeTrackColor: const Color(0xFF4858E8),
                      onChanged: (v) => setState(() => _notifEnabled = v),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _menuItem(
                    icon: Icons.lock_outline,
                    title: 'Privasi',
                    subtitle: 'Atur siapa yang bisa melihat profilmu',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('KEAMANAN'),
                  const SizedBox(height: 8),
                  _menuItem(
                    icon: Icons.delete_forever_outlined,
                    iconColor: const Color(0xFFD3454D),
                    iconBg: const Color(0xFFFFF0F0),
                    title: 'Ajukan penghapusan akun',
                    subtitle: 'Penghapusan akun secara permanen',
                    onTap: () => _showDeleteConfirm(context),
                  ),

                  const SizedBox(height: 24),
                  // Keluar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout,
                          color: Color(0xFFD3454D), size: 20),
                      title: const Text('Keluar dari akun',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: Color(0xFFD3454D))),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: Color(0xFFD3454D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // About
                  Center(
                    child: Column(
                      children: [
                        const MamoLogo(size: 28),
                        const SizedBox(height: 6),
                        Text('MAMO v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400)),
                      ],
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

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: const Text(
          'Akun dan semua data akan dihapus permanen. Aksi ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              showSnack(context, 'Hubungi admin untuk penghapusan akun.');
            },
            style: TextButton.styleFrom(foregroundColor: MamoColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.5)),
      );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _iconBox(IconData icon, {Color? color, Color? bg}) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color ?? const Color(0xFF4858E8)),
    );
  }

  Widget _menuItem({
    required IconData icon,
    Color? iconColor,
    Color? iconBg,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: ListTile(
        leading: _iconBox(icon, color: iconColor, bg: iconBg),
        title: Text(title,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: Color(0xFF172039))),
        subtitle: subtitle != null
            ? Text(subtitle,
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
