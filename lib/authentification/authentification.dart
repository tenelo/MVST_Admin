// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/authentification/pin_creation.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/main.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/services/auth_service.dart';
import 'package:mvst_admin/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════════
// FONCTION GLOBALE (conservée pour la page OTP)
// ════════════════════════════════════════════════════════════════
Future<void> creerCompteAdmin(
  String authUid,
  String nom,
  String prenoms,
  String telephone,
  String ville,
  String pin,
  BuildContext context,
) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: "$telephone@gmail.com",
          password: '${pin}mv',
        );

    final User? user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName('$nom $prenoms');

      String gare = '';
      String role = 'admin';

      try {
        final responseAdmin = await http.post(
          apiUri('verifierAdmin.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'telephone': telephone}),
        );
        if (responseAdmin.statusCode == 200) {
          final dataAdmin = jsonDecode(responseAdmin.body);
          gare = dataAdmin['gare'] ?? '';
          role = dataAdmin['role'] ?? 'admin';
        }
      } catch (e) {
        debugPrint('Erreur récupération gare/role: $e');
      }

      await http.post(
        apiUri('ajouterAdmin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUtilisateur': user.uid,
          'idAuth': authUid,
          'nom': nom,
          'prenoms': prenoms,
          'residence': ville,
          'telephone': telephone,
          'mail': "$telephone@gmail.com",
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gare', gare);
      await prefs.setString('uid', user.uid);
      await prefs.setString('role', role);

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Accueil()),
          (route) => false,
        );
      }
    }
  } catch (e) {
    debugPrint('Erreur création compte admin: $e');
  }
}

// ════════════════════════════════════════════════════════════════
// PAGE D'AUTHENTIFICATION (inscription admin)
// ════════════════════════════════════════════════════════════════

class PageDAuthentification extends StatefulWidget {
  final String telephone;
  final String gare;
  final String role;

  const PageDAuthentification({
    super.key,
    required this.telephone,
    required this.gare,
    required this.role,
  });

  @override
  _PageDAuthentificationState createState() => _PageDAuthentificationState();
}

class _PageDAuthentificationState extends State<PageDAuthentification> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();

  bool _isLoading = false;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  // ── Étape 1 : valider le formulaire et vérifier si le numéro existe en BD ──

  Future<void> _verifierEtContinuer() async {
    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty ||
        _residenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 241, 94, 94),
          content: Text(
            'Veuillez remplir tous les champs.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinCreation(onPinConfirmed: _finaliserCreation),
      ),
    );
  }

  // ── Creation admin via Sanctum (serveur gere flux nouveau/existant) ─────────

  Future<void> _finaliserCreation(String pin) async {
    // Appel unique : le serveur gere flux A (nouveau) vs B (deja client),
    // hashe le PIN et rend un token. PinCreation navigue vers Accueil apres.
    final response = await ApiClient.instance
        .post('admin/register', body: {
          'telephone': widget.telephone,
          'pin': pin,
          'nom': _nomController.text.trim(),
          'prenoms': _prenomController.text.trim(),
          'residence': _residenceController.text.trim(),
        })
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      // Remonter l'erreur : PinCreation attend une exception pour ne pas
      // naviguer vers Accueil sur echec.
      throw Exception(data['message'] ?? 'Echec de la creation du compte');
    }

    final utilisateur = data['utilisateur'] as Map<String, dynamic>;

    await TokenStorage.saveToken(data['token'] as String);

    final nomComplet = [
      utilisateur['nom']?.toString() ?? '',
      utilisateur['prenoms']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join(' ').trim();
    await _secureStorage.write(
      key: 'user_idUtilisateur',
      value: utilisateur['idUtilisateur']?.toString() ?? '',
    );
    await _secureStorage.write(key: 'user_name', value: nomComplet);

    // Pont SharedPreferences (gare/uid/role encore lus par main()/profil.dart).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gare', utilisateur['gare']?.toString() ?? widget.gare);
    await prefs.setString(
        'uid', utilisateur['idUtilisateur']?.toString() ?? '');
    await prefs.setString('role', utilisateur['role']?.toString() ?? widget.role);

    await AuthService.chargerDepuisStorage();
    // Pas de navigation ici : PinCreation._validerConfirmation navigue.
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  Widget _buildChamp({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    final c = Config.colors;
    final double sw = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        cursorColor: c.authAccent,
        enableSuggestions: false,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        style: TextStyle(color: c.authTextPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(
            color: c.authTextSecondary,
            fontSize: sw * 0.034,
          ),
          prefixIcon: Icon(icone, color: c.authAccent, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double sw = MediaQuery.widthOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: c.authBackground,
      body: SafeArea(
        child: _buildFormulaire(c, sw),
      ),
    );
  }

  Widget _buildFormulaire(dynamic c, double sw) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, 20 + bottomInset),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Container(
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
          ),
          const SizedBox(height: 20),
          Text(
            'Créer un compte Admin',
            style: TextStyle(
              color: c.authTextPrimary,
              fontSize: sw * 0.055,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Remplissez les informations ci-dessous',
            style: TextStyle(color: c.authTextSecondary, fontSize: sw * 0.032),
          ),
          const SizedBox(height: 14),

          // Numéro affiché en lecture seule
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: c.authCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.authBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_outlined, color: c.authAccent, size: 20),
                const SizedBox(width: 12),
                Text(
                  '+225 ${widget.telephone}',
                  style: TextStyle(
                    color: c.authTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _buildChamp(
            controller: _nomController,
            label: 'Nom',
            icone: Icons.person_outline,
          ),
          _buildChamp(
            controller: _prenomController,
            label: 'Prénoms',
            icone: Icons.person_outline,
          ),
          _buildChamp(
            controller: _residenceController,
            label: 'Lieu de résidence',
            icone: Icons.location_on_outlined,
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.authButton,
                foregroundColor: c.authTextPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _verifierEtContinuer();
                    },
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

}

// ════════════════════════════════════════════════════════════════
// PAGE DE VERIFICATION (OTP — conservée, non utilisée dans le flux principal)
// ════════════════════════════════════════════════════════════════

class PageDeVerification extends StatefulWidget {
  final String verificationId;
  final String nom;
  final String prenoms;
  final String telephone;
  final String ville;
  final String? uidDejaAuthentifie;

  const PageDeVerification({
    super.key,
    required this.verificationId,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.ville,
    this.uidDejaAuthentifie,
  });

  @override
  _PageDeVerificationState createState() => _PageDeVerificationState();
}

class _PageDeVerificationState extends State<PageDeVerification> {
  final TextEditingController _codeController = TextEditingController();
  String idAuth = '';
  bool _isDisposed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _isDisposed = true;
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: screenWidth * 0.08,
            right: screenWidth * 0.08,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.06),
              Container(
                width: screenWidth * 0.20,
                height: screenWidth * 0.20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.authAccent, width: 2),
                  color: c.authCardBackground,
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: c.authAccent,
                  size: screenWidth * 0.09,
                ),
              ),
              SizedBox(height: screenHeight * 0.035),
              Text(
                'Code de vérification',
                style: TextStyle(
                  color: c.authTextPrimary,
                  fontSize: screenWidth * 0.056,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.008),
              Text(
                'Entrez le code reçu par SMS au',
                style: TextStyle(
                  color: c.authTextSecondary,
                  fontSize: screenWidth * 0.032,
                ),
              ),
              Text(
                '+225 ${widget.telephone}',
                style: TextStyle(
                  color: c.authAccent,
                  fontSize: screenWidth * 0.034,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.045),
              Container(
                decoration: BoxDecoration(
                  color: c.authCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.authBorder, width: 1.5),
                ),
                child: TextFormField(
                  maxLength: 6,
                  cursorColor: c.authAccent,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.authTextPrimary,
                    fontSize: screenWidth * 0.055,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: c.authTextSecondary,
                      fontSize: screenWidth * 0.05,
                      letterSpacing: 8,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.022,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 6) {
                      _seConnecterParNumTelephone(widget.verificationId, value);
                    }
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.035),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.058,
                child: ElevatedButton(
                  onPressed: _isLoading || _codeController.text.isEmpty
                      ? null
                      : () => _seConnecterParNumTelephone(
                          widget.verificationId,
                          _codeController.text,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.authButton,
                    foregroundColor: c.authTextPrimary,
                    elevation: 0,
                    disabledBackgroundColor: c.authButtonDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: c.authTextPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Valider',
                          style: TextStyle(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seConnecterParNumTelephone(
    String verificationId,
    String smsCode,
  ) async {
    if (_isDisposed) return;
    setState(() => _isLoading = true);

    try {
      String uid;

      if (widget.uidDejaAuthentifie != null &&
          widget.uidDejaAuthentifie!.isNotEmpty) {
        uid = widget.uidDejaAuthentifie!;
      } else {
        final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        final UserCredential authResult = await FirebaseAuth.instance
            .signInWithCredential(credential);
        final User? user = authResult.user;
        if (user == null) return;

        await user.updateDisplayName('${widget.nom} ${widget.prenoms}');
        uid = user.uid;
      }

      setState(() => idAuth = uid);

      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PinCreation(
              onPinConfirmed: (pin) => creerCompteAdmin(
                uid,
                widget.nom,
                widget.prenoms,
                widget.telephone,
                widget.ville,
                pin,
                context,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Une erreur est survenue. Réessayez.';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'session-expired':
              message =
                  'Le code a expiré. Veuillez redemander un nouveau code.';
              break;
            case 'invalid-verification-code':
              message = 'Code incorrect. Vérifiez le SMS et réessayez.';
              break;
            case 'too-many-requests':
              message = 'Trop de tentatives. Réessayez dans quelques minutes.';
              break;
            case 'network-request-failed':
              message = 'Erreur réseau. Vérifiez votre connexion.';
              break;
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }
}
