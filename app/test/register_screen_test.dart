import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mamo/screens/login_screen.dart';
import 'package:mamo/screens/register_screen.dart';

/// Router mini khusus test: hanya Login <-> Register,
/// meniru pasangan route nyata di lib/router.dart.
GoRouter _miniRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      ],
    );

/// Test UI + behaviour halaman Register.
/// Tidak ada panggilan jaringan: register baru memanggil API saat tombol ditekan
/// dan form sudah valid + checkbox dicentang.
void main() {
  /// Setel viewport: lebar supaya tidak ada overflow palsu (font test Ahem
  /// jauh lebih lebar dari Inter) dan tinggi supaya form panjang tidak
  /// perlu di-scroll saat di-tap.
  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    setViewport(tester);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
    await tester.pump();
  }

  testWidgets('menampilkan seluruh elemen sesuai desain', (tester) async {
    await pump(tester, const RegisterScreen());

    expect(find.text('BUAT AKUN BARU'), findsOneWidget);
    expect(find.byKey(const Key('register-title')), findsOneWidget);
    expect(
      find.text('Bergabung dan mulai temukan kebutuhan Anda dalam satu aplikasi.'),
      findsOneWidget,
    );
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Masukkan nama lengkap'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Masukkan email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masukkan kata sandi'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    expect(find.text('Ulangi kata sandi'), findsOneWidget);
    expect(find.byKey(const Key('register-agreement')), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Sudah punya akun? '), findsOneWidget);
    expect(find.text('Masuk sekarang'), findsOneWidget);
  });

  testWidgets('judul: "Daftar ke " hitam + "MAMO" biru #4858E8', (tester) async {
    await pump(tester, const RegisterScreen());
    final rich = tester.widget<RichText>(find.byKey(const Key('register-title')));
    final root = rich.text as TextSpan;
    final spans = root.children!.cast<TextSpan>();
    expect(root.style?.color, const Color(0xFF000000));
    expect(spans[0].text, 'Daftar ke ');
    expect(spans[1].text, 'MAMO');
    expect(spans[1].style?.color, const Color(0xFF4858E8));
  });

  testWidgets('teks persetujuan: S&K dan Kebijakan Privasi berwarna biru',
      (tester) async {
    await pump(tester, const RegisterScreen());

    final richTexts = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text)
        .whereType<TextSpan>()
        .toList();

    TextSpan? agreement;
    for (final t in richTexts) {
      if (t.children != null &&
          t.children!.any((c) => c is TextSpan && c.text == 'Saya setuju dengan ')) {
        agreement = t;
        break;
      }
    }
    expect(agreement, isNotNull, reason: 'teks persetujuan harus ada');

    final kids = agreement!.children!.cast<TextSpan>();
    final sk = kids.firstWhere((k) => k.text == 'Syarat dan Ketentuan');
    final pk = kids.firstWhere((k) => k.text == 'Kebijakan Privasi MAMO');
    expect(sk.style?.color, const Color(0xFF4858E8));
    expect(pk.style?.color, const Color(0xFF4858E8));
  });

  testWidgets('4 field input, semua tingginya 40dp (sesuai desain)', (tester) async {
    await pump(tester, const RegisterScreen());

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      expect(tester.getSize(fields.at(i)).height, closeTo(40, 2),
          reason: 'input ke-$i harus ~40dp');
    }
  });

  testWidgets('ikon user, mail, dan 2 lock ada', (tester) async {
    await pump(tester, const RegisterScreen());
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
  });

  testWidgets('toggle password: dua toggle independen', (tester) async {
    await pump(tester, const RegisterScreen());

    // keduanya mulai tersembunyi
    expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    // buka yang pertama saja
    await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // buka yang kedua juga
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
  });

  testWidgets('checkbox persetujuan kosong secara default, bisa dicentang', (tester) async {
    await pump(tester, const RegisterScreen());
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byKey(const Key('register-agreement-box')));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('validasi: mendaftar tanpa isi apa pun menampilkan error', (tester) async {
    await pump(tester, const RegisterScreen());

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Nama minimal 2 karakter'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password minimal 8 karakter'), findsOneWidget);
    expect(find.text('Persetujuan wajib dicentang'), findsOneWidget);
  });

  testWidgets('validasi: konfirmasi kata sandi tidak sama', (tester) async {
    await pump(tester, const RegisterScreen());

    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'password456');
    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
  });

  testWidgets('navigasi: Login "Daftar sekarang" -> Register', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _miniRouter())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Daftar sekarang'), findsOneWidget);

    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('navigasi: Register "Masuk sekarang" -> Login', (tester) async {
    setViewport(tester);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: _miniRouter())),
    );
    await tester.pumpAndSettle();

    // mulai dari Register (tap "Daftar sekarang" dari Login)
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Masuk sekarang'), findsOneWidget);

    // balik ke Login lewat link di Register
    await tester.tap(find.text('Masuk sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('SELAMAT DATANG KEMBALI'), findsOneWidget);
  });
}
