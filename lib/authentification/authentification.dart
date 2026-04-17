// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/main.dart';

class PageDAuthentification extends StatefulWidget {
  const PageDAuthentification({super.key});

  @override
  _PageDAuthentificationState createState() => _PageDAuthentificationState();
}

class _PageDAuthentificationState extends State<PageDAuthentification> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();
  String? _gareSelectionnee;
  List<String> listeDesGares = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _recupererGares();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  Future<void> _recupererGares() async {
    try {
      final response =
          await http.get(Uri.parse('https://mvst.tenelo.cloud/gares.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            listeDesGares = List<String>.from(
                data['gares'].map((g) => g['gare'].toString()));
          });
        }
      }
    } catch (e) {}
  }

  // ── Vérification via PostgreSQL ────────────────────────────────────────────
  Future<bool> _verificationTelephoneAdmin(String numero) async {
    try {
      final response = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/verifierTelephoneAdmin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': numero}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['existe'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Accès Refusé",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  "\nLe numéro utilisé est déjà associé à un administrateur existant.",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        SystemNavigator.pop();
                      });
                    },
                    child: const Text("OK",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _envoyerCodeDeVerification() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _residenceController.text.isEmpty ||
        _gareSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color.fromARGB(255, 241, 94, 94),
        content: Text('Veuillez remplir tous les champs.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ));
      return;
    }

    setState(() => _isLoading = true);

    final surListe =
        await _verificationTelephoneAdmin(_telephoneController.text);
    if (surListe) {
      setState(() => _isLoading = false);
      return;
    }

    final numeroTelephone = '+225${_telephoneController.text}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: numeroTelephone,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur de vérification.')));
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PageDeVerification(
                  verificationId: verificationId,
                  nom: _nomController.text,
                  prenoms: _prenomController.text,
                  telephone: _telephoneController.text,
                  ville: _residenceController.text,
                  gare: _gareSelectionnee!,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de l'envoi du code")));
      }
    }

    setState(() => _isLoading = false);
  }

  Widget _buildChamp({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
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
        style: TextStyle(color: c.authTextPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(
              color: c.authTextSecondary, fontSize: screenWidth * 0.034),
          prefixIcon: Icon(icone, color: c.authAccent, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.04),

                // ── Logo ──────────────────────────────────────────────
                Container(
                  width: screenWidth * 0.20,
                  height: screenWidth * 0.20,
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
                        fontSize: screenWidth * 0.042,
                        fontFamily: 'Lobster',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                Text(
                  'Créer un compte Admin',
                  style: TextStyle(
                    color: c.authTextPrimary,
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                SizedBox(height: screenHeight * 0.006),

                Text(
                  'Remplissez les informations ci-dessous',
                  style: TextStyle(
                      color: c.authTextSecondary,
                      fontSize: screenWidth * 0.032),
                ),

                SizedBox(height: screenHeight * 0.035),

                _buildChamp(
                    controller: _nomController,
                    label: 'Nom',
                    icone: Icons.person_outline),
                _buildChamp(
                    controller: _prenomController,
                    label: 'Prénoms',
                    icone: Icons.person_outline),
                _buildChamp(
                  controller: _telephoneController,
                  label: 'Numéro de téléphone',
                  icone: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                _buildChamp(
                    controller: _residenceController,
                    label: 'Lieu de résidence',
                    icone: Icons.location_on_outlined),

                // ── Dropdown gares ────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: c.authCardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.authBorder, width: 1.5),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _gareSelectionnee,
                    dropdownColor: c.authCardBackground,
                    iconEnabledColor: c.authAccent,
                    style: TextStyle(color: c.authTextPrimary),
                    items: listeDesGares.map((gare) {
                      return DropdownMenuItem<String>(
                        value: gare,
                        child: Text(gare,
                            style: TextStyle(color: c.authTextPrimary)),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _gareSelectionnee = value),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Gare',
                      labelStyle: TextStyle(color: c.authTextSecondary),
                      prefixIcon: Icon(Icons.location_city_outlined,
                          color: c.authAccent, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // ── Bouton ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.058,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.authButton,
                      foregroundColor: c.authTextPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _envoyerCodeDeVerification,
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: c.authTextPrimary, strokeWidth: 2.5),
                              ),
                              const SizedBox(width: 12),
                              Text('Envoi en cours...',
                                  style: TextStyle(
                                      color: c.authTextPrimary,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Text(
                            'Recevoir le code par SMS',
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page de vérification ──────────────────────────────────────────────────────
class PageDeVerification extends StatefulWidget {
  final String verificationId;
  final String nom;
  final String prenoms;
  final String telephone;
  final String ville;
  final String gare;

  const PageDeVerification({
    super.key,
    required this.verificationId,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.ville,
    required this.gare,
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
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.06),

                // ── Icône SMS ─────────────────────────────────────────
                Container(
                  width: screenWidth * 0.20,
                  height: screenWidth * 0.20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.authAccent, width: 2),
                    color: c.authCardBackground,
                  ),
                  child: Icon(Icons.sms_outlined,
                      color: c.authAccent, size: screenWidth * 0.09),
                ),

                SizedBox(height: screenHeight * 0.035),

                Text(
                  'Code de vérification',
                  style: TextStyle(
                      color: c.authTextPrimary,
                      fontSize: screenWidth * 0.056,
                      fontWeight: FontWeight.bold),
                ),

                SizedBox(height: screenHeight * 0.008),

                Text('Entrez le code reçu par SMS au',
                    style: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: screenWidth * 0.032)),

                Text(
                  '+225 ${widget.telephone}',
                  style: TextStyle(
                      color: c.authAccent,
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.bold),
                ),

                SizedBox(height: screenHeight * 0.045),

                // ── Champ code ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: c.authCardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.authBorder, width: 1.5),
                  ),
                  child: TextFormField(
                    maxLength: 6,
                    cursorColor: c.authAccent,
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
                          letterSpacing: 8),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.022),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),

                SizedBox(height: screenHeight * 0.035),

                // ── Bouton valider ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.058,
                  child: ElevatedButton(
                    onPressed: _isLoading || _codeController.text.isEmpty
                        ? null
                        : () => _seConnecterParNumTelephone(
                            widget.verificationId, _codeController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.authButton,
                      foregroundColor: c.authTextPrimary,
                      elevation: 0,
                      disabledBackgroundColor: c.authButtonDisabled,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: c.authTextPrimary, strokeWidth: 2.5),
                          )
                        : Text('Valider',
                            style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _seConnecterParNumTelephone(
      String verificationId, String smsCode) async {
    if (_isDisposed) return;
    setState(() => _isLoading = true);

    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;
      if (user == null) return;

      await user.updateDisplayName('${widget.nom} ${widget.prenoms}');
      await user.updatePhoneNumber(PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode));

      setState(() => idAuth = user.uid);

      if (mounted) {
        await _creerCompteAdmin(
            idAuth, widget.nom, widget.prenoms, widget.telephone, context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la connexion...')));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _creerCompteAdmin(
    String authUid,
    String nom,
    String prenoms,
    String telephone,
    BuildContext context,
  ) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: "$telephone@gmail.com",
        password: telephone,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName('$nom $prenoms');

        // ── PostgreSQL via PHP ─────────────────────────────────────────
        await http.post(
          Uri.parse('https://mvst.tenelo.cloud/ajouterAdmin.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idUtilisateur': user.uid,
            'idAuth': authUid,
            'nom': '$nom $prenoms',
            'gare': widget.gare,
            'telephone': telephone,
            'mail': "$telephone@gmail.com",
          }),
        );

        // ✅ Plus de deconnexionEtReconnexion
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Accueil()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur création compte admin: $e');
    }
  }
}
