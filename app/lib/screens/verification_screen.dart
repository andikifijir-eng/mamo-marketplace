import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/common.dart';

/// Alur verifikasi mahasiswa: submit -> admin review -> approved/rejected.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _nim = TextEditingController();
  String? _campusId;
  bool _busy = false;
  bool _showForm = false;

  @override
  void dispose() {
    _nim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nim.text.trim().length < 3) {
      showSnack(context, 'NIM/NIP minimal 3 karakter', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(verificationRepoProvider).submit(
            campusId: _campusId,
            studentIdentifier: _nim.text.trim(),
          );
      ref.invalidate(verificationStatusProvider);
      if (mounted) {
        setState(() => _showForm = false);
        showSnack(context, 'Pengajuan terkirim. Tunggu review admin.');
      }
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(verificationStatusProvider);
    final campuses = ref.watch(campusesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Mahasiswa')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorState(
          message: ApiClient.errorMessage(e),
          onRetry: () => ref.invalidate(verificationStatusProvider),
        ),
        data: (data) {
          final status = data['status'] as String? ?? 'none';
          final v = data['verification'] as Map<String, dynamic>?;

          if (status == 'approved') {
            return const EmptyState(
              message: 'Akun kamu sudah terverifikasi sebagai mahasiswa.',
              icon: Icons.verified,
            );
          }
          if (status == 'pending') {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: MamoColors.infoBg, shape: BoxShape.circle),
                  child: const Icon(Icons.schedule, size: 36, color: MamoColors.primary),
                ),
                const SizedBox(height: 18),
                const Text('Pengajuan Sedang Diproses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'NIM yang diajukan: ${v?['studentIdentifier'] ?? '-'}\nAdmin akan meninjau pengajuanmu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: MamoColors.textSecondary),
                ),
              ]),
            );
          }

          // none / rejected -> tampilkan form
          if (!_showForm && status == 'none') {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: MamoColors.infoBg, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_outlined,
                      size: 36, color: MamoColors.primary),
                ),
                const SizedBox(height: 18),
                const Text('Verifikasi Identitas Mahasiswa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Verifikasi meningkatkan kepercayaan pembeli dan membuka fitur penjual.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: MamoColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: const Text('Mulai Verifikasi'),
                ),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (status == 'rejected')
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MamoColors.dangerBg,
                    borderRadius: BorderRadius.circular(MamoRadius.md),
                  ),
                  child: const Row(children: [
                    Icon(Icons.error_outline, color: MamoColors.danger, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Pengajuan sebelumnya ditolak. Ajukan ulang dengan data benar.',
                          style: TextStyle(fontSize: 12, color: MamoColors.danger)),
                    ),
                  ]),
                ),
              const Text('Kampus',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              campuses.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat daftar kampus',
                    style: TextStyle(fontSize: 12, color: MamoColors.danger)),
                data: (list) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(MamoRadius.md),
                    border: Border.all(color: MamoColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _campusId,
                      hint: const Text('Pilih kampus', style: TextStyle(fontSize: 13)),
                      items: list
                          .map((c) => DropdownMenuItem<String>(
                                value: c['id'] as String,
                                child: Text(c['name'] as String,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _campusId = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('NIM / NIP',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nim,
                decoration: const InputDecoration(hintText: 'Contoh: 3.24.21.0.01'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kirim Pengajuan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
