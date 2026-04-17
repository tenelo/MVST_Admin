// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/authentification/authentification.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> enregistrerGare(String gare, String uid, String profil) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gare', gare);
    await prefs.setString('uid', uid);
     await prefs.setString('profil', profil);
  }

  Future<void> sauthentifier(BuildContext context, String telephone) async {
    setState(() => _isLoading = true);

    try {
      // ── Vérifier dans PostgreSQL ──────────────────────────────────────
      final response = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/verifierAdmin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': telephone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true || data['existe'] != true) {
          // ── Numéro non autorisé ─────────────────────────────────────
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Accès Refusé",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                    "Le numéro que vous utilisez n'est pas autorisé à se connecter."),
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
          setState(() => _isLoading = false);
          return;
        }

        // ── Numéro autorisé → connexion Firebase ──────────────────────
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: "$telephone@gmail.com",
          password: telephone,
        );

        final uid = data['uid'] as String;
        final gare = data['gare'] as String;
        final profil = data['profil'] as String? ?? 'admin';

        await enregistrerGare(gare, uid,profil);

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Accueil()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PageDAuthentification()),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo ────────────────────────────────────────────
                  Container(
                    width: screenWidth * 0.22,
                    height: screenWidth * 0.22,
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
                          fontSize: screenWidth * 0.045,
                          fontFamily: 'Lobster',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  Text(
                    'Connexion Admin',
                    style: TextStyle(
                      color: c.authTextPrimary,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.008),

                  Text(
                    'Entrez votre numéro pour continuer',
                    style: TextStyle(
                      color: c.authTextSecondary,
                      fontSize: screenWidth * 0.033,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.045),

                  // ── Champ téléphone ──────────────────────────────────
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
                          fontWeight: FontWeight.w500),
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Ex: 0505050505',
                        hintStyle: TextStyle(
                          color: c.authTextSecondary,
                          fontSize: screenWidth * 0.035,
                        ),
                        prefixIcon:
                            Icon(Icons.phone_outlined, color: c.authAccent),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.018),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre numéro';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Entrez un numéro valide à 10 chiffres';
                        }
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // ── Bouton connexion ─────────────────────────────────
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
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                await sauthentifier(
                                    context, _phoneNumberController.text);
                              }
                            },
                      child: _isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: c.authTextPrimary, strokeWidth: 2.5),
                            )
                          : Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: c.authTextSecondary, thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03),
                        child: Text('ou',
                            style: TextStyle(
                                color: c.authTextSecondary,
                                fontSize: screenWidth * 0.032)),
                      ),
                      Expanded(
                          child: Divider(
                              color: c.authTextSecondary, thickness: 1)),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PageDAuthentification()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pas de compte ? ',
                            style: TextStyle(
                                color: c.authTextSecondary,
                                fontSize: screenWidth * 0.034),
                          ),
                          TextSpan(
                            text: 'Créer un compte',
                            style: TextStyle(
                              color: c.authAccent,
                              fontSize: screenWidth * 0.034,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: c.authAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
