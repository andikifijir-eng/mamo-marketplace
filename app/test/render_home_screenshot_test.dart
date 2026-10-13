import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamo/models/models.dart';
import 'package:mamo/screens/home_screen.dart';
import 'package:mamo/screens/home_shell.dart';
import 'package:mamo/state/providers.dart';

Product _p({
  required String id,
  required String name,
  required int price,
  required String loc,
  String? img,
}) =>
    Product(
      id: id,
      name: name,
      price: price,
      condition: 'used',
      description: 'Deskripsi produk',
      stock: 1,
      status: 'active',
      sellerId: 's1',
      location: loc,
      images: img != null ? [ProductImage(id: 'i_$id', imageUrl: img)] : [],
    );

void main() {
  testWidgets('Render and save Home screen preview PNG', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repaintKey = GlobalKey();

    final mockProducts = [
      _p(
        id: 'p1',
        name: 'Macbook Air M1 2020',
        price: 8250000,
        loc: 'Banyumanik',
      ),
      _p(
        id: 'p2',
        name: 'iPhone 11 Pro 64GB',
        price: 5200000,
        loc: 'Tembalang',
      ),
      _p(
        id: 'p3',
        name: 'Buku Kalkulus Purcell Edisi 9',
        price: 150000,
        loc: 'Tembalang',
      ),
      _p(
        id: 'p4',
        name: 'Kursi Belajar Ergonomis',
        price: 320000,
        loc: 'Ngaliyan',
      ),
    ];

    final mockCategories = [
      Category(id: 'c1', name: 'Buku', icon: 'book'),
      Category(id: 'c2', name: 'Elektronik', icon: 'laptop'),
      Category(id: 'c3', name: 'Fashion', icon: 'shirt'),
      Category(id: 'c4', name: 'Kos', icon: 'home'),
      Category(id: 'c5', name: 'Gaming', icon: 'gamepad'),
      Category(id: 'c6', name: 'Lainnya', icon: 'more'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeProductsProvider.overrideWith((ref) async => mockProducts),
          categoriesProvider.overrideWith((ref) async => mockCategories),
          notificationsProvider.overrideWith(
              (ref) async => (items: <AppNotification>[], unread: 2)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: repaintKey,
            child: const HomeShell(
              child: HomeScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Render widget tree to PNG
    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File('d:/MAMO/preview/home-flutter-preview.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    // Also copy to artifacts directory for direct user embedding
    final artifactFile = File(
        'C:/Users/LENOVO/.gemini/antigravity/brain/12c624b2-fc2b-4663-9ade-b288a741439b/home-flutter-preview.png');
    await artifactFile.writeAsBytes(byteData.buffer.asUint8List());

    print('Preview saved successfully: ${file.path} (${file.lengthSync()} bytes)');
  });
}
