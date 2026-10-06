import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamo/screens/login_screen.dart';

/// Test UI Login — memastikan tampilan sesuai desain Figma dan
/// behaviour dasar (toggle password, checkbox) masih berfungsi.
///
/// Widget dibungkus ProviderScope + MaterialApp; tidak ada panggilan jaringan
/// selama hanya merender (login baru memanggil API saat tombol ditekan).
void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('menampilkan seluruh elemen sesuai desain', (tester) async {
    await pumpLogin(tester);

    expect(find.text('SELAMAT DATANG KEMBALI'), findsOneWidget);
    expect(find.byKey(const Key('login-title')), findsOneWidget);
    expect(find.text('Lanjutkan menemukan barang di sekitarmu.'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Masukkan email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masukkan kata sandi'), findsOneWidget);
    expect(find.text('Ingat saya'), findsOneWidget);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Belum punya akun? '), findsOneWidget);
    expect(find.text('Daftar sekarang'), findsOneWidget);
  });

  testWidgets('judul "MAMO" berwarna biru #4858E8, "Masuk ke" hitam',
      (tester) async {
    await pumpLogin(tester);
    final rich = tester.widget<RichText>(find.byKey(const Key('login-title')));
    final root = rich.text as TextSpan;
    final spans = root.children!.cast<TextSpan>();
    // "Masuk ke " mewarisi warna hitam dari span induk (style anak = null)
    expect(root.style?.color, const Color(0xFF000000));
    expect(spans[0].text, 'Masuk ke ');
    expect(spans[0].style?.color, isNull);
    expect(spans[1].text, 'MAMO');
    expect(spans[1].style?.color, const Color(0xFF4858E8));
  });

  testWidgets('label kecil biru dan huruf kapital semua', (tester) async {
    await pumpLogin(tester);
    final t = tester.widget<Text>(find.text('SELAMAT DATANG KEMBALI'));
    expect(t.style?.color, const Color(0xFF4858E8));
    expect(t.style?.letterSpacing, 1.2);
  });

  testWidgets('latar halaman putih', (tester) async {
    await pumpLogin(tester);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
  });

  testWidgets('ikon email dan lock ada di dalam input', (tester) async {
    await pumpLogin(tester);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('ikon show/hide password berganti saat ditekan', (tester) async {
    await pumpLogin(tester);

    // Awalnya password tersembunyi -> ikon "visibility_off"
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('checkbox: tercentang default, ikon centang hilang saat dimatikan',
      (tester) async {
    await pumpLogin(tester);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Ingat saya'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('Ingat saya'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('validasi: email & password kosong ditolak tanpa memanggil API',
      (tester) async {
    await pumpLogin(tester);

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    // pesan validasi muncul; tidak ada request jaringan (tidak crash/exception)
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('validasi format email salah', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'bukan-email');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('tinggi kotak input 46 dan tombol Masuk 46 (sesuai desain)',
      (tester) async {
    await pumpLogin(tester);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(fields.at(i));
      expect(size.height, closeTo(46, 2), reason: 'input ke-$i harus ~46dp');
    }

    // tombol Masuk: cari ElevatedButton
    final btn = find.byType(ElevatedButton);
    expect(btn, findsOneWidget);
    expect(tester.getSize(btn).height, closeTo(46, 2));
  });
}
