import 'package:shared_preferences/shared_preferences.dart';

/// Simpan token & data user secara lokal.
class SessionStore {
  static const _kToken = 'mamo_token';
  static const _kUserId = 'mamo_user_id';
  static const _kRole = 'mamo_role';
  static const _kName = 'mamo_name';
  static const _kEmail = 'mamo_email';
  static const _kOnboarded = 'mamo_onboarded';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<void> save({
    required String token,
    required String userId,
    required String role,
    String? name,
    String? email,
  }) async {
    final p = await _p;
    await p.setString(_kToken, token);
    await p.setString(_kUserId, userId);
    await p.setString(_kRole, role);
    if (name != null) await p.setString(_kName, name);
    if (email != null) await p.setString(_kEmail, email);
  }

  static Future<String?> get token async => (await _p).getString(_kToken);
  static Future<String?> get userId async => (await _p).getString(_kUserId);
  static Future<String?> get role async => (await _p).getString(_kRole);
  static Future<String?> get name async => (await _p).getString(_kName);
  static Future<String?> get email async => (await _p).getString(_kEmail);

  static Future<bool> get onboarded async => (await _p).getBool(_kOnboarded) ?? false;
  static Future<void> setOnboarded(bool v) async => (await _p).setBool(_kOnboarded, v);

  static Future<void> clear() async {
    final p = await _p;
    await p.remove(_kToken);
    await p.remove(_kUserId);
    await p.remove(_kRole);
    await p.remove(_kName);
    await p.remove(_kEmail);
  }
}
