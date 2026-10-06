import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../data/auth_repository.dart';
import '../data/repositories.dart';
import '../models/models.dart';

final authRepoProvider = Provider((ref) => AuthRepository());
final productRepoProvider = Provider((ref) => ProductRepository());
final cartRepoProvider = Provider((ref) => CartRepository());
final orderRepoProvider = Provider((ref) => OrderRepository());
final chatRepoProvider = Provider((ref) => ChatRepository());
final notificationRepoProvider = Provider((ref) => NotificationRepository());
final verificationRepoProvider = Provider((ref) => VerificationRepository());
final sellerRepoProvider = Provider((ref) => SellerRepository());
final uploadRepoProvider = Provider((ref) => UploadRepository());
final userRepoProvider = Provider((ref) => UserRepository());

/// Status autentikasi aplikasi.
///
/// `initializing` dan `loading` SENGAJA dipisah:
/// - `initializing` = masih memuat sesi tersimpan saat app dibuka (hanya sekali).
///   Router memakai ini untuk menahan user di splash.
/// - `loading` = ada operasi auth yang sedang jalan (login/register).
///   Router TIDAK boleh memakai ini, kalau dipakai user akan terlempar ke
///   splash saat login berlangsung dan nyangkut di sana.
class AuthState {
  final bool initializing;
  final bool loading;
  final bool loggedIn;
  final User? user;
  final String? error;

  const AuthState({
    this.initializing = true,
    this.loading = false,
    this.loggedIn = false,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? initializing, bool? loading, bool? loggedIn, User? user, String? error}) =>
      AuthState(
        initializing: initializing ?? this.initializing,
        loading: loading ?? this.loading,
        loggedIn: loggedIn ?? this.loggedIn,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AuthState()) {
    restore();
  }

  Future<void> restore() async {
    final token = await SessionStore.token;
    if (token == null || token.isEmpty) {
      state = const AuthState(initializing: false);
      return;
    }
    try {
      final user = await ref.read(authRepoProvider).me();
      state = AuthState(initializing: false, loggedIn: true, user: user);
    } catch (_) {
      // Token invalid/expired → paksa login ulang
      await SessionStore.clear();
      state = const AuthState(initializing: false);
    }
  }

  /// Tidak mengubah `initializing` — supaya router tidak melempar ke splash.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true);
    try {
      final user = await ref.read(authRepoProvider).login(email: email, password: password);
      state = AuthState(initializing: false, loggedIn: true, user: user);
      return true;
    } catch (e) {
      state = AuthState(initializing: false, loggedIn: false, error: ApiClient.errorMessage(e));
      return false;
    }
  }

  /// Tidak mengubah `initializing` — supaya router tidak melempar ke splash.
  Future<bool> register(String email, String password, String fullName, {String? phone}) async {
    state = state.copyWith(loading: true);
    try {
      final user = await ref.read(authRepoProvider)
          .register(email: email, password: password, fullName: fullName, phone: phone);
      state = AuthState(initializing: false, loggedIn: true, user: user);
      return true;
    } catch (e) {
      state = AuthState(initializing: false, loggedIn: false, error: ApiClient.errorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepoProvider).logout();
    state = const AuthState(initializing: false, loggedIn: false);
  }

  Future<void> refresh() async {
    try {
      final user = await ref.read(authRepoProvider).me();
      state = state.copyWith(user: user);
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

/// Kategori
final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.read(productRepoProvider).categories());

/// Kampus (untuk form verifikasi)
final campusesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.read(verificationRepoProvider).campuses());

/// Produk untuk halaman Home
final homeProductsProvider = FutureProvider<List<Product>>(
    (ref) => ref.read(productRepoProvider).search(limit: 20).then((r) => r.products));

/// Keranjang
final cartProvider = FutureProvider.autoDispose((ref) => ref.read(cartRepoProvider).get());

/// Favorit
final favoritesProvider = FutureProvider.autoDispose(
    (ref) => ref.read(productRepoProvider).favorites());

/// Notifikasi
final notificationsProvider = FutureProvider.autoDispose(
    (ref) => ref.read(notificationRepoProvider).list());

/// Order list
final ordersProvider = FutureProvider.autoDispose.family<List<Order>, bool>(
    (ref, asSeller) => ref.read(orderRepoProvider).list(asSeller: asSeller));

/// Seller dashboard
final sellerDashboardProvider = FutureProvider.autoDispose(
    (ref) => ref.read(sellerRepoProvider).dashboard());

/// Verifikasi status
final verificationStatusProvider = FutureProvider.autoDispose(
    (ref) => ref.read(verificationRepoProvider).status());

/// Seller listing (dipakai dashboard & form jual barang)
final sellerProductsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.read(sellerRepoProvider).products());

/// Detail produk
final productDetailProvider = FutureProvider.autoDispose.family((ref, String id) =>
    ref.read(productRepoProvider).detail(id));

/// Review produk
final productReviewsProvider = FutureProvider.autoDispose.family(
    (ref, String id) => ref.read(productRepoProvider).reviews(id));
