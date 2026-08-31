import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage securise du token d'authentification Laravel (app admin).
/// Cle distincte de l'app cliente pour cohabitation sur un meme appareil.
class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _key = 'admin_auth_token';

  static Future<void> saveToken(String token) {
    return _storage.write(key: _key, value: token);
  }

  static Future<String?> getToken() {
    return _storage.read(key: _key);
  }

  static Future<void> deleteToken() {
    return _storage.delete(key: _key);
  }
}
