// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/authentification/authentification.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> sauthentifier(BuildContext context, String telephhone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Authentification de l'utilisateur avec l'e-mail et le mot de passe
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "$telephhone@gmail.com",
        password: telephhone,
      );

      // Redirection vers la page HomeAdmin après authentification réussie
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => const Accueil(),
        ),
      );
    } catch (e) {
      // Redirection vers la page Authentification en cas d'échec
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PageDAuthentification(),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
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
