import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/session.dart';
import '../core/theme.dart';

class _Page {
  final IconData icon;
  final String title;
  final String desc;
  const _Page(this.icon, this.title, this.desc);
}

/// 4 halaman onboarding sesuai Figma (Onboarding-1..4).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _Page(Icons.storefront_outlined, 'Jual Beli Sesama Mahasiswa',
        'Temukan barang berkualitas dari mahasiswa di kampus sekitarmu.'),
    _Page(Icons.near_me_outlined, 'Barang di Sekitar Kamu',
        'Lihat produk terdekat, bisa COD langsung tanpa ongkir mahal.'),
    _Page(Icons.chat_bubble_outline, 'Chat Langsung Penjual',
        'Tanya kondisi barang dan nego harga langsung dengan penjualnya.'),
    _Page(Icons.verified_user_outlined, 'Aman & Terverifikasi',
        'Akun mahasiswa terverifikasi supaya transaksi lebih aman.'),
  ];

  Future<void> _finish() async {
    await SessionStore.setOnboarded(true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Lewati',
                    style: TextStyle(color: MamoColors.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (c, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: MamoColors.brandGradient,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          child: Icon(p.icon, size: 84, color: Colors.white),
                        ),
                        const SizedBox(height: 40),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
                        const SizedBox(height: 12),
                        Text(p.desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, color: MamoColors.textSecondary, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? MamoColors.primary : MamoColors.cardBorder,
                    borderRadius: BorderRadius.circular(MamoRadius.pill),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut);
                  }
                },
                child: Text(isLast ? 'Mulai Sekarang' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
