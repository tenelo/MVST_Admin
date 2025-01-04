// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> enregistrerGare(String _gare, String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gare', _gare);
    await prefs.setString('uid', uid);
  }

  Future<void> sauthentifier(BuildContext context, String telephone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérification si le numéro est présent dans la collection 'admins'
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('telephone', isEqualTo: telephone)
          .get();

      if (snapshot.docs.isEmpty) {
        // Si le numéro n'est pas trouvé dans la collection 'admins', on affiche une alerte et ferme l'application
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                const Text(
                  "Accès Refusé",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
                "Le numéro que vous utilisez n'est pas autorisé à se connecter."),
            actions: [
              TextButton(
                onPressed: () {
                  // Fermer l'application après l'alerte
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 500), () {
                    SystemNavigator.pop();
                  });
                },
                child: const Text(
                  "OK",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return; // Arrêter l'exécution si le numéro n'est pas trouvé
      }

      // Si le numéro est trouvé dans la collection 'admins', on continue avec l'authentification
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "$telephone@gmail.com",
        password: telephone,
      );

      // Récupérer l'uid de l'utilisateur
      String uid = userCredential.user!.uid;

      // Récupérer le lieu de résidence (champ 'gare') depuis Firestore
      DocumentSnapshot<Map<String, dynamic>> adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        String gare = adminDoc.data()?['gare'] ?? 'Non défini';

        // Enregistrer le lieu de résidence dans SharedPreferences
        await enregistrerGare(gare, uid);

        // Redirection vers la page Accueil après authentification réussie
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => const Accueil(),
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur, redirection vers la page Authentification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PageDAuthentification(),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: const Text(
          'Vérification du numéro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextFormField(
                    maxLength: 10,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Colors.white),
                      labelText: 'Numéro de téléphone',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.lightBlue, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }

                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Entrez un numéro valide à 10 chiffres';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Config.colors.bleuFonce2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(
                            color: Color.fromARGB(255, 80, 165, 235)),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });
                              sauthentifier(
                                  context, _phoneNumberController.text);
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(
                  height: 100,
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PageDAuthentification(),
                    ),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pas de compte',
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: '\tCréer un compte?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
