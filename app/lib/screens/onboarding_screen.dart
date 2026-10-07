import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session.dart';
import '../state/providers.dart';

/// Onboarding post-login sesuai desain Figma (310x682):
/// latar biru solid #365DF2 dengan pola garis tipis abstrak (putih ~20%),
/// logo MAMO di ~51% tinggi, judul putih 3 baris rata kiri, subtitle
/// biru-muda 2 baris. Desain tidak memuat tombol/dot — lanjut dengan tap.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _done = false;

  /// Logika lama dipertahankan: flag "sudah onboarding" tetap ditulis.
  /// Sesudah login -> Home; first-run sebelum login -> Login.
  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    await SessionStore.setOnboarded(true);
    if (!mounted) return;
    context.go(ref.read(authProvider).loggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF365DF2),
      body: SafeArea(
        child: Semantics(
          button: true,
          label: 'Lanjut',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _finish,
            child: LayoutBuilder(
              builder: (context, cons) {
                final h = cons.maxHeight;
                // proporsi desain 310x682
                const m = 22.0; // margin kiri (desain x22/310)
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _AbstractLinePainter()),
                    ),
                    // logo: desain y350/682
                    Positioned(
                      top: h * 0.5145,
                      left: 19,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: Color(0xFF365DF2)),
                          ),
                          const SizedBox(width: 6),
                          const Text('MAMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                height: 1,
                              )),
                        ],
                      ),
                    ),
                    // judul: desain y404/682
                    Positioned(
                      top: h * 0.584,
                      left: m,
                      right: m,
                      child: const Text(
                        'Barang bagus, dari\norang terdekat di\nsekitarmu.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // subtitle: desain y510/682
                    Positioned(
                      top: h * 0.7405,
                      left: m,
                      right: m,
                      child: Text(
                        'Marketplace aman dengan pengawasan '
                        'dan verifikasi yang terpercaya.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13.5,
                          height: 1.41,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Pola garis abstrak tipis yang menutupi seluruh layar di belakang konten
/// (desain: beberapa busur besar + kurva landai, putih ~20% di atas biru).
class _AbstractLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const refW = 310.0, refH = 682.0;
    final sx = size.width / refW, sy = size.height / refH;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.scale(sx, sy);

    // ── busur kiri (cekung ke kanan), desain c≈(150,480) r≈127
    p.color = Colors.white.withValues(alpha: 0.20);
    canvas.drawArc(Rect.fromCircle(center: const Offset(150, 480), radius: 127),
        2.83, 0.98, false, p);

    // ── busur kanan nyaris tegak, desain c≈(700,530) r≈447
    p.color = Colors.white.withValues(alpha: 0.18);
    canvas.drawArc(Rect.fromCircle(center: const Offset(700, 530), radius: 447),
        2.93, 0.42, false, p);

    // ── kurva landai atas-kiri (dua sejajar)
    p.color = Colors.white.withValues(alpha: 0.17);
    canvas.drawPath(
        Path()
          ..moveTo(-60, 193)
          ..quadraticBezierTo(11, 10, 64, 205),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(20, 205)
          ..quadraticBezierTo(14, 6, 84, 212),
        p);

    // ── kurva tengah-kanan membuka ke atas
    p.color = Colors.white.withValues(alpha: 0.15);
    canvas.drawPath(
        Path()
          ..moveTo(146, 205)
          ..quadraticBezierTo(163, 8, 242, 205),
        p);

    // ── busur dekoratif bawah-kiri
    p.color = Colors.white.withValues(alpha: 0.14);
    canvas.drawArc(Rect.fromCircle(center: const Offset(10, 570), radius: 106),
        1.40, 2.44, false, p);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
