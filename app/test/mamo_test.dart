import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamo/core/theme.dart';
import 'package:mamo/models/models.dart';
import 'package:mamo/state/providers.dart';
import 'package:mamo/widgets/common.dart';

void main() {
  group('Model parsing', () {
    test('Product.fromJson memetakan relasi seller/kategori/_count', () {
      final p = Product.fromJson({
        'id': 'p1',
        'name': 'Monitor LG',
        'price': 1350000,
        'stock': 3,
        'condition': 'used',
        'status': 'active',
        'sellerId': 's1',
        'location': 'Tembalang',
        'images': [
          {'id': 'i1', 'imageUrl': 'http://x/a.jpg'},
        ],
        'seller': {
          'id': 's1',
          'profile': {'fullName': 'Penjual 2', 'avatar': null},
        },
        'category': {'id': 'c1', 'name': 'Elektronik'},
        '_count': {'favorites': 4, 'reviews': 2},
      });

      expect(p.name, 'Monitor LG');
      expect(p.price, 1350000);
      expect(p.sellerName, 'Penjual 2');
      expect(p.categoryName, 'Elektronik');
      expect(p.favoriteCount, 4);
      expect(p.imageUrl, 'http://x/a.jpg');
      expect(p.conditionLabel, 'Bekas');
    });

    test('Order.fromJson + label status bahasa Indonesia', () {
      final o = Order.fromJson({
        'id': 'abcdef1234567890',
        'buyerId': 'b1',
        'sellerId': 's1',
        'totalAmount': 55000,
        'deliveryMethod': 'cod',
        'status': 'completed',
        'items': [
          {'id': 'oi1', 'productId': 'p1', 'quantity': 1, 'price': 55000, 'subtotal': 55000},
        ],
      });
      expect(o.statusLabel, 'Selesai');
      expect(o.shortId, 'abcdef12');
      expect(o.items.length, 1);
      expect(o.items.first.subtotal, 55000);
    });

    test('CartItem menghitung subtotal dari harga × qty', () {
      final it = CartItem.fromJson({
        'id': 'ci1',
        'quantity': 3,
        'product': {'id': 'p1', 'name': 'Buku', 'price': 25000, 'stock': 10},
      });
      expect(it.subtotal, 75000);
    });

    test('StatusPill.order memetakan semua status order', () {
      for (final s in Order.statusLabels.keys) {
        final pill = StatusPill.order(s);
        expect(pill.label.isNotEmpty, true, reason: 'status $s harus punya label');
      }
      expect(StatusPill.order('pending').label, 'Menunggu');
      expect(StatusPill.order('ready').label, 'Siap');
      expect(StatusPill.order('rejected').label, 'Ditolak');
    });
  });

  group('Widget render', () {
    testWidgets('ProductCard menampilkan nama & harga rupiah', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: MamoTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: ProductCard(
              name: 'Monitor LG 24 inch IPS',
              price: 1350000,
              location: 'Tembalang',
            ),
          ),
        ),
      ));

      expect(find.text('Monitor LG 24 inch IPS'), findsOneWidget);
      expect(find.textContaining('1.350.000'), findsOneWidget);
      expect(find.text('Tembalang'), findsOneWidget);
    });

    testWidgets('EmptyState menampilkan pesan kustom', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyState(message: 'Keranjang kamu masih kosong')),
      ));
      expect(find.text('Keranjang kamu masih kosong'), findsOneWidget);
    });

    testWidgets('ErrorState memanggil onRetry saat tombol ditekan', (tester) async {
      var retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorState(message: 'Koneksi gagal', onRetry: () => retried = true),
        ),
      ));

      expect(find.text('Koneksi gagal'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(retried, true);
    });

    testWidgets('MamoLogo menampilkan wordmark MAMO', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MamoLogo()),
      ));
      expect(find.text('MAMO'), findsOneWidget);
    });

    testWidgets('StatusPill merender ikon + label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatusPill.order('completed')),
      ));
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });

    testWidgets('AsyncView menampilkan loading lalu data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncView<List<String>>(
            snapshot: const AsyncSnapshot.waiting(),
            builder: (d) => Text('${d.length}'),
          ),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncView<List<String>>(
            snapshot: AsyncSnapshot.withData(ConnectionState.done, ['a', 'b']),
            builder: (d) => Text('${d.length} item'),
          ),
        ),
      ));
      expect(find.text('2 item'), findsOneWidget);
    });
  });

  group('Provider dasar', () {
    test('AuthState default: initializing=true & belum login (mencegah redirect dini)', () {
      // Diuji langsung pada nilai default — bukan lewat container, karena
      // konstruksi AuthNotifier memicu restore() async yang membuat hasil tidak deterministik.
      const s = AuthState();
      expect(s.initializing, true);
      expect(s.loggedIn, false);
      expect(s.user, isNull);
    });

    test('AuthState default: loading=false (login tidak boleh mengunci di splash)', () {
      // Regression: dulu `loading` dipakai router untuk menahan di splash.
      // Saat login berjalan, loading=true -> user terlempar ke /splash dan
      // nyangkut di sana setelah login sukses. `loading` hanya untuk tombol.
      const s = AuthState();
      expect(s.loading, false);
    });

    test('AuthState.copyWith mempertahankan nilai yang tidak diubah', () {
      const s = AuthState(loading: true, loggedIn: false);
      final loggedIn = s.copyWith(loading: false, loggedIn: true);
      expect(loggedIn.loggedIn, true);
      expect(loggedIn.loading, false);
    });
  });
}
