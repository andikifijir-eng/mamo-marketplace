import '../core/api_client.dart';
import '../core/session.dart';
import '../models/models.dart';

class AuthRepository {
  final _dio = ApiClient.instance.dio;

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final token = res.data['token'] as String;
    final user = User.fromJson(res.data['user']);
    await SessionStore.save(
      token: token, userId: user.id, role: user.role,
      name: user.displayName, email: user.email,
    );
    return user;
  }

  Future<User> login({required String email, required String password}) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    final user = User.fromJson(res.data['user']);
    await SessionStore.save(
      token: token, userId: user.id, role: user.role,
      name: user.displayName, email: user.email,
    );
    return user;
  }

  Future<User> me() async {
    final res = await _dio.get('/auth/me');
    return User.fromJson(res.data['user']);
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await SessionStore.clear();
  }

  Future<String?> forgotPassword(String email) async {
    final res = await _dio.post('/auth/forgot-password', data: {'email': email});
    return res.data['resetToken'] as String?;
  }

  Future<void> resetPassword({required String token, required String password}) async {
    await _dio.post('/auth/reset-password', data: {'token': token, 'password': password});
  }
}

class UserRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> me() async => (await _dio.get('/users/me')).data;

  Future<void> updateProfile({
    String? fullName, String? phone, String? avatar, String? bio,
  }) async {
    await _dio.put('/users/me', data: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
    });
  }

  Future<List<Map<String, dynamic>>> addresses() async {
    final res = await _dio.get('/users/me/addresses/list');
    return List<Map<String, dynamic>>.from(res.data['addresses']);
  }

  Future<void> addAddress({
    required String label, required String address,
    double? latitude, double? longitude, bool isDefault = false,
  }) async {
    await _dio.post('/users/me/addresses', data: {
      'label': label, 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isDefault': isDefault,
    });
  }

  Future<Map<String, dynamic>> sellerProfile(String id) async =>
      (await _dio.get('/users/$id')).data;
}
