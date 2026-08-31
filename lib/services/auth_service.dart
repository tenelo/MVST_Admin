import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvst_admin/authentification/connection.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/services/token_storage.dart';

class AppUser {
  const AppUser({required this.uid, this.displayName});
  final String uid;
  final String? displayName;
}

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? _token;
  static String? _idUtilisateur;
  static String? _nomUtilisateur;

  static Future<void> chargerDepuisStorage() async {
    _token = await TokenStorage.getToken();
    _idUtilisateur = await _storage.read(key: 'user_idUtilisateur');
    _nomUtilisateur = await _storage.read(key: 'user_name');
  }

  static bool estConnecte() {
    return _token != null;
  }

  static AppUser? getUtilisateur() {
    if (_idUtilisateur == null) return null;
    return AppUser(uid: _idUtilisateur!, displayName: _nomUtilisateur);
  }

  static String? getUid() {
    return _idUtilisateur;
  }

  static Future<bool> verifierEtRediriger(BuildContext context) async {
    if (!estConnecte()) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
      return false;
    }
    return true;
  }

  static bool verifier() {
    return estConnecte();
  }

  static Future<void> deconnexion() async {
    try {
      await ApiClient.instance.post('logout');
    } catch (_) {}

    await TokenStorage.deleteToken();

    await _storage.delete(key: 'user_idUtilisateur');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_phone');
    await _storage.delete(key: 'user_pin');
    _token = null;
    _idUtilisateur = null;
    _nomUtilisateur = null;

    await FirebaseAuth.instance.signOut();
  }

  static void afficherSnackNonConnecte(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Text(
          'Vous n\'etes pas authentifie. Connectez-vous pour acceder a cette page.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
