import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mamo/data/auth_repository.dart';
import 'package:mamo/models/models.dart';
import 'package:mamo/router.dart';
import 'package:mamo/screens/home_screen.dart';
import 'package:mamo/screens/login_screen.dart';
import 'package:mamo/screens/splash_screen.dart';
import 'package:mamo/state/providers.dart';

/// Repo palsu dengan delay yang bisa diatur.
class _FakeAuthRepo extends AuthRepository {
  final Duration delay;
  _FakeAuthRepo(this.delay);

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(delay);
    return User(
      id: 'u1',
      email: email,
      role: 'buyer',
      accountStatus: 'active',
      profile: UserProfile(fullName: 'Pembeli Uji'),
    );
  }

  @override
  Future<User> me() async => throw Exception('tidak ada sesi');

  @override
  Future<void> logout() async {}
}

Future<void> _runLoginFlow(WidgetTester tester, Duration loginDelay) async {
  SharedPreferences.setMockInitialValues({'flutter.mamo_onboarded': true});

  final container = ProviderContainer(
    overrides: [authRepoProvider.overrideWithValue(_FakeAuthRepo(loginDelay))],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: container.read(routerProvider)),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget, reason: 'harus sampai di Login');

  await tester.enterText(find.byType(TextFormField).first, 'pembeli@mamo.id');
  await tester.enterText(find.byType(TextFormField).last, 'password123');
  await tester.tap(find.text('Masuk'));

  // majukan waktu 6 detik (melewati semua delay)
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }

  // diagnostik: layar apa yang sedang tampil?
  // ignore: avoid_print
  print('DIAG  splash=${find.byType(SplashScreen).evaluate().length} '
      'login=${find.byType(LoginScreen).evaluate().length} '
      'home=${find.byType(HomeScreen).evaluate().length} '
      'spinner=${find.byType(CircularProgressIndicator).evaluate().length}');
}

void main() {
  testWidgets('login LAMBAT (2s) berakhir di Home', (tester) async {
    await _runLoginFlow(tester, const Duration(seconds: 2));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('login CEPAT (200ms) berakhir di Home', (tester) async {
    await _runLoginFlow(tester, const Duration(milliseconds: 200));
    expect(find.byType(HomeScreen), findsOneWidget,
        reason: 'login cepat tidak boleh nyangkut di splash');
  });

  testWidgets('login SANGAT CEPAT (10ms) berakhir di Home', (tester) async {
    await _runLoginFlow(tester, const Duration(milliseconds: 10));
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
