import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamo/models/models.dart';
import 'package:mamo/screens/home_screen.dart';
import 'package:mamo/screens/home_shell.dart';
import 'package:mamo/state/providers.dart';

Product _sampleProd() => Product(
      id: 'p1',
      name: 'Macbook Air M1 2020',
      price: 8250000,
      condition: 'used',
      description: 'Mulus COD',
      stock: 1,
      status: 'active',
      sellerId: 's1',
      categoryId: 'cat-1',
      categoryName: 'Elektronik',
      location: 'Tembalang',
      images: [],
    );

void main() {
  testWidgets('Home Screen: memverifikasi seluruh komponen visual sesuai desain Figma',
      (tester) async {
    final prod = _sampleProd();
    final cat = Category(id: 'c1', name: 'Buku', icon: 'book');

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeProductsProvider.overrideWith((ref) async => [prod]),
          categoriesProvider.overrideWith((ref) async => [cat]),
          notificationsProvider.overrideWith(
              (ref) async => (items: <AppNotification>[], unread: 1)),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header: Logo MAMO & Chat / Notifikasi
    expect(find.text('MAMO'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Greeting & Profile Button
    expect(find.text('SELAMAT DATANG'), findsOneWidget);
    expect(find.textContaining('Halo,'), findsOneWidget);
    expect(find.text('Temukan barang bagus dari pengguna di sekitarmu.'),
        findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // 3. Search Bar
    expect(find.text('Cari Barang yang kamu butuhkan...'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);

    // 4. Informasi Lokasi
    expect(find.textContaining('Menampilkan area sekitar'), findsOneWidget);
    expect(find.textContaining('Universitas Diponegoro'), findsOneWidget);

    // 5. Jelajahi Kategori
    expect(find.text('Jelajahi Kategori'), findsOneWidget);
    expect(find.text('Lihat semua'), findsNWidgets(2)); // kategori + pilihan lokal
    expect(find.text('Buku'), findsOneWidget);

    // 6. Banner "DEKAT DENGANMU"
    expect(find.text('DEKAT DENGANMU'), findsOneWidget);
    expect(find.textContaining('Temukan barang di'), findsOneWidget);
    expect(find.text('Lihat barang terdekat'), findsOneWidget);

    // 7. Pilihan Lokal & Barang di sekitarmu
    expect(find.text('PILIHAN LOKAL'), findsOneWidget);
    expect(find.text('Barang di sekitarmu'), findsOneWidget);

    // Scroll ke produk
    await tester.scrollUntilVisible(
      find.text('Macbook Air M1 2020'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // 8. Kartu Produk & Floating Wishlist Heart
    expect(find.text('Macbook Air M1 2020'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('HomeShell: memverifikasi bottom navigation bar (Home, Listing Saya, Profile, floating FAB +)',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShell(
            child: Scaffold(body: Center(child: Text('Konten'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Listing Saya'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
