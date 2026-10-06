import 'package:dio/dio.dart';

import 'session.dart';

/// Base URL backend MAMO.
/// - Android emulator: http://10.0.2.2:4000/api
/// - Desktop/web/iOS sim: http://localhost:4000/api
/// - Device fisik: ganti ke IP LAN mesin (mis. http://192.168.1.10:4000/api)
String get baseUrl {
  const override = String.fromEnvironment('MAMO_API', defaultValue: '');
  if (override.isNotEmpty) return override;
  return 'http://localhost:4000/api';
}

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SessionStore.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  Dio get dio => _dio;

  /// Normalisasi error jadi pesan yang bisa ditampilkan ke user.
  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (data is Map && data['details'] is List && (data['details'] as List).isNotEmpty) {
        final d = (data['details'] as List).first;
        if (d is Map && d['message'] != null) return d['message'].toString();
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Cek jaringan kamu.';
        case DioExceptionType.connectionError:
          return 'Tidak bisa terhubung ke server MAMO ($baseUrl).';
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) return 'Sesi habis, silakan login ulang.';
          if (e.response?.statusCode == 403) return 'Kamu tidak punya akses ke aksi ini.';
          if (e.response?.statusCode == 404) return 'Data tidak ditemukan.';
          return 'Server menolak permintaan (${e.response?.statusCode}).';
        default:
          return 'Terjadi kesalahan. Coba lagi.';
      }
    }
    return e.toString();
  }
}
