import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mamo/models/models.dart';
import 'package:mamo/screens/chat_list_screen.dart';
import 'package:mamo/screens/notifications_screen.dart';
import 'package:mamo/state/providers.dart';
import 'package:mamo/core/theme.dart';

/// Data uji mengikuti desain Figma (bukan mock baru di aplikasi).
Conversation _conv({String name = 'Penjual 1', int unread = 0, String? prod = 'MacBook Air M1 2020'}) =>
    Conversation(
      id: 'c1', buyerId: 'me', sellerId: 's1',
      productName: prod, otherName: name,
      lastMessage: 'Boleh ketemu di perpustakaan kampus?',
      lastMessageAt: DateTime(2026, 10, 9, 10, 42), unreadCount: unread,
    );

AppNotification _notif({bool read = false, String type = 'chat'}) => AppNotification(
      id: 'n1', type: type, title: 'Pesan baru dari Penjual 1',
      body: 'Boleh, silakan ajukan penawaran dulu.', isRead: read,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );

void main() {
  testWidgets('Chat: header bulat + search, tab Aktif(dengan badge)/Selesai, avatar & badge unread', (tester) async {
    final conv = _conv(unread: 2);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        conversationsProvider.overrideWith((ref) async => [conv]),
        ordersProvider(false).overrideWith((ref) async => <Order>[]),
        ordersProvider(true).overrideWith((ref) async => <Order>[]),
      ],
      child: const MaterialApp(home: ChatListScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2),
        reason: 'badge jumlah di tab Aktif + badge unread di baris');
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.text('Penjual 1'), findsOneWidget);
    expect(find.text('MacBook Air M1 2020'), findsOneWidget);
    expect(find.text('10:42'), findsOneWidget, reason: 'waktu pesan terakhir');
    expect(find.text('Boleh ketemu di perpustakaan kampus?'), findsOneWidget);

    // avatar: lingkaran, warna biru brand untuk "Penjual 1"
    final circles = tester.widgetList<Container>(find.byWidgetPredicate((w) =>
        w is Container && w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle));
    expect(
        circles.any((c) => (c.decoration as BoxDecoration).color == const Color(0xFF4858E8)),
        isTrue,
        reason: 'avatar Penjual 1 memakai biru brand #4858E8');
  });

  testWidgets('Chat: tab Selesai kosong menampilkan empty state', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        conversationsProvider.overrideWith((ref) async => []) ,
        ordersProvider(false).overrideWith((ref) async => <Order>[]),
        ordersProvider(true).overrideWith((ref) async => <Order>[]),
      ],
      child: const MaterialApp(home: ChatListScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada percakapan'), findsOneWidget);
  });

  testWidgets('Notifikasi: judul, aksi Tandai dibaca, heading TERBARU, item + titik unread', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        notificationsProvider.overrideWith((ref) async =>
            (items: [_notif(), _notif(read: true, type: 'price')], unread: 1)),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Tandai dibaca'), findsOneWidget);
    expect(find.text('TERBARU'), findsOneWidget);
    expect(find.text('Pesan baru dari Penjual 1'), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.text('2 menit lalu'), findsNWidgets(2));
    // satu titik unread (yang sudah dibaca tidak punya)
    final dots = tester.widgetList<Container>(find.byWidgetPredicate((w) =>
        w is Container && w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration as BoxDecoration).color == MamoColors.primary));
    expect(dots.length, 1);
  });
}
