import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

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
            phone: _phone.text.trim(),
            bio: _bio.text.trim(),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profil',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
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
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Ceritakan sedikit tentang kamu',
            ),
          ),
          const SizedBox(height: 16),
          Text('Email: ${user?.email ?? '-'}',
              style: const TextStyle(fontSize: 12, color: MamoColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Simpan Perubahan'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Tentang Aplikasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MamoRadius.md),
              border: Border.all(color: MamoColors.cardBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const MamoLogo(size: 30),
              const SizedBox(height: 10),
              const Text('MAMO — Marketplace Mahasiswa Online',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Versi 1.0.0\nAPI: $baseUrl',
                  style: const TextStyle(fontSize: 11, color: MamoColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 24),
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
    );
  }
}
