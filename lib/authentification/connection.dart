// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/authentification/authentification.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/main.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/mesfonctions/keyboard_notifier.dart';
import 'package:mvst_admin/authentification/clavier_numerique.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/services/auth_service.dart';
import 'package:mvst_admin/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _etape = 0;
  String _telephone = '';
  String _pin = '';
  bool _isLoading = false;
  String? _erreur;
  String _gare = '';
  String _uid = '';
  String _role = 'admin';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> enregistrerSession(String gare, String uid, String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gare', gare);
    await prefs.setString('uid', uid);
    await prefs.setString('role', role);
  }

  Future<void> _continuer() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _erreur = null;
    });

    try {
      final response = await http.post(
        apiUri('verifierAdmin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': _phoneNumberController.text.trim()}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode != 200) {
        setState(() => _erreur = 'Erreur serveur. Réessayez.');
        return;
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true || data['existe'] != true) {
        if (context.mounted) {
          final c = Config.colors;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: c.authDialogBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.gpp_bad, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Accès Refusé",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Votre numéro n'est pas autorisé à utiliser cette application."
                "\n\nVeuillez contacter les administrateurs MVST.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Future.delayed(const Duration(milliseconds: 500), () {
                      SystemNavigator.pop();
                    });
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      _gare = data['gare'] as String? ?? '';
      _uid = data['uid'] as String? ?? '';
      _role = data['role'] as String? ?? 'admin';
      final bool compteExiste = data['compteExiste'] == true;

      if (!compteExiste) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PageDAuthentification(
                telephone: _phoneNumberController.text.trim(),
                gare: _gare,
                role: _role,
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _telephone = _phoneNumberController.text.trim();
        _etape = 1;
        _pin = '';
        _erreur = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _erreur = 'Erreur de connexion. Réessayez.';
      });
    }
  }

  void _onChiffre(String chiffre) {
    if (_pin.length >= 4) return;
    setState(() {
      _erreur = null;
      _pin += chiffre;
    });
    if (_pin.length == 4) _seConnecter();
  }

  void _onSupprimer() {
    if (_pin.isEmpty) return;
    setState(() {
      _erreur = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _seConnecter() async {
    setState(() => _isLoading = true);
    try {
      // Source de verite : Laravel Sanctum.
      final response = await ApiClient.instance
          .post('admin/login', body: {'telephone': _telephone, 'pin': _pin})
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        if (mounted) {
          setState(() {
            _erreur = data['message'] as String? ?? 'Code Secret incorrect.';
            _pin = '';
            _isLoading = false;
          });
        }
        return;
      }

      final utilisateur = data['utilisateur'] as Map<String, dynamic>;

      // Token Sanctum (future source de verite unique).
      await TokenStorage.saveToken(data['token'] as String);

      // Cles lues par AuthService.chargerDepuisStorage().
      final nomComplet = [
        utilisateur['nom']?.toString() ?? '',
        utilisateur['prenoms']?.toString() ?? '',
      ].where((s) => s.isNotEmpty).join(' ').trim();
      await _secureStorage.write(
        key: 'user_idUtilisateur',
        value: utilisateur['idUtilisateur']?.toString() ?? _uid,
      );
      await _secureStorage.write(key: 'user_name', value: nomComplet);

      // Valeurs metier issues de la reponse serveur (fallback sur celles
      // recuperees a l'etape telephone si absentes).
      _gare = utilisateur['gare']?.toString() ?? _gare;
      _role = utilisateur['role']?.toString() ?? _role;
      _uid = utilisateur['idUtilisateur']?.toString() ?? _uid;

      // Pont transition : on continue d'ecrire gare/role/uid en
      // SharedPreferences, encore lus par main() et profil.dart tant que
      // le Lot 1c n'a pas migre ces lectures vers AuthService.
      await enregistrerSession(_gare, _uid, _role);

      // Rafraichir le cache memoire d'AuthService avant navigation.
      await AuthService.chargerDepuisStorage();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Accueil()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur = 'Erreur de connexion. Réessayez.';
          _pin = '';
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      body: SafeArea(
        child: _etape == 0
            ? _buildEtapeTelephone(c, sw, sh)
            : _buildEtapePin(c, sw, sh),
      ),
    );
  }

  Widget _buildEtapeTelephone(dynamic c, double sw, double sh) {
    return KeyboardHeightProvider(
      builder: (_, keyboardHeight) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          sw * 0.08,
          0,
          sw * 0.08,
          keyboardHeight + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: sh * 0.10),
              _Logo(colors: c, sw: sw),
              SizedBox(height: sh * 0.04),
              Text(
                'Connexion Admin',
                style: TextStyle(
                  color: c.authTextPrimary,
                  fontSize: sw * 0.06,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: sh * 0.008),
              Text(
                'Entrez votre numéro pour continuer',
                style: TextStyle(
                  color: c.authTextSecondary,
                  fontSize: sw * 0.033,
                ),
              ),
              SizedBox(height: sh * 0.045),
              Container(
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: TextFormField(
                  maxLength: 10,
                  cursorColor: c.authAccent,
                  style: TextStyle(
                    color: c.authTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'Ex: 0505050505',
                    hintStyle: TextStyle(
                      color: c.authTextSecondary,
                      fontSize: sw * 0.035,
                    ),
                    prefixIcon: Icon(Icons.phone_outlined, color: c.authAccent),
                    contentPadding: EdgeInsets.symmetric(vertical: sh * 0.018),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Veuillez entrer votre numéro';
                    if (v.length < 10) return 'Numéro invalide';
                    return null;
                  },
                ),
              ),
              SizedBox(height: sh * 0.03),
              SizedBox(
                width: double.infinity,
                height: sh * 0.058,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.authButton,
                    foregroundColor: c.authTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _continuer,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: c.authTextPrimary,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Vérification...',
                              style: TextStyle(
                                color: c.authTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: sw * 0.038,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtapePin(dynamic c, double sw, double sh) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: c.authTextPrimary,
              size: 20,
            ),
            onPressed: () => setState(() {
              _etape = 0;
              _pin = '';
              _erreur = null;
            }),
          ),
        ),
        SizedBox(height: sh * 0.03),
        _Logo(colors: c, sw: sw),
        SizedBox(height: sh * 0.03),
        Text(
          'Entrez votre Code Secret',
          style: TextStyle(
            color: c.authTextPrimary,
            fontSize: sw * 0.052,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sh * 0.01),
        Text(
          '+225 $_telephone',
          style: TextStyle(
            color: c.authAccent,
            fontSize: sw * 0.032,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sh * 0.05),
        _PinDots(longueur: _pin.length, erreur: _erreur != null, colors: c),
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Text(
            _erreur!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const Spacer(),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: CircularProgressIndicator(color: c.authAccent),
          )
        else
          ClavierNumerique(
            onChiffre: _onChiffre,
            onSupprimer: _onSupprimer,
            colors: c,
            sw: sw,
          ),
        SizedBox(height: sh * 0.04),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final dynamic colors;
  final double sw;
  const _Logo({required this.colors, required this.sw});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: sw * 0.20,
      height: sw * 0.20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.authAccent, width: 2),
        color: c.authCardBackground,
      ),
      child: Center(
        child: Text(
          'MVST',
          style: TextStyle(
            color: c.authAccent,
            fontSize: sw * 0.042,
            fontFamily: 'Lobster',
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int longueur;
  final bool erreur;
  final dynamic colors;
  const _PinDots({
    required this.longueur,
    required this.erreur,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final rempli = i < longueur;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rempli ? c.authAccent : Colors.transparent,
            border: Border.all(
              color: erreur ? Colors.red : c.authAccent,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
