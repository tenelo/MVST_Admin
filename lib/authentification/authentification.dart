// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/main.dart';
import 'package:mysql1/mysql1.dart';

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
  MySqlConnection? conn;
  String? _gareSelectionnee;
  final List<String> listeDesGares = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    recupererToutesLesGares();
  }

  Future<void> _connectToDatabase() async {
    conn = await Connexion.connexionDB();
  }

  Future<void> recupererToutesLesGares() async {
    conn ??= await Connexion.connexionDB();
    try {
      final results = await conn!.query('SELECT gare FROM Gares');
      listeDesGares.clear(); // Nettoyer la liste avant de la remplir
      for (var row in results) {
        listeDesGares.add(row['gare']);
      }
      setState(() {}); // Mettre à jour l'interface utilisateur
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la récupération des gares...'),
      ));
    }
  }

  Future<bool> verificationListeAdmin(String numero) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('numero', isEqualTo: numero)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Le numéro est dans la liste noire
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
                "\nLe numéro utilisé est déjà associé à un administrateur existant."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Fermer l'application
                  Future.delayed(const Duration(milliseconds: 500), () {
                    SystemNavigator.pop();
                  });
                },
                child: Text("OK",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return true; // Numéro trouvé dans la liste admin
      }
      return false; // Numéro non trouvé dans la liste admin
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la vérification, reprenez le processus'),
      ));
      return false; // En cas d'erreur
    }
  }

  Future<void> _envoyerCodeDeVerification() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _residenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color.fromARGB(255, 241, 94, 94),
        content: Text(
          'Veuillez remplir tous les champs.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Vérification dans la liste admin
    bool surListeNoire =
        await verificationListeAdmin(_telephoneController.text);

    if (surListeNoire) {
      // Si le numéro est dans la liste admin, on arrête l'exécution
      setState(() {
        _isLoading = false;
      });
      return; // Ne pas continuer l'exécution si le numéro est dans la liste admin
    }

    String numeroTelephone = '+225${_telephoneController.text}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: numeroTelephone,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur de vérification.'),
          ));
        },
        codeSent: (String verificationId, int? resendToken) async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PageDeVerification(
                verificationId: verificationId,
                nom: _nomController.text,
                prenoms: _prenomController.text,
                telephone: _telephoneController.text,
                ville: _residenceController.text,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de l\'envoi du code'),
      ));
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
        iconTheme: IconThemeData(
          color: Config.colors.jauneBlanc,
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: const Text(
          'Authentification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    labelText: 'Nom',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlue, width: 2.0),
                    ),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    labelText: 'Prénoms',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlue, width: 2.0),
                    ),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  maxLength: 10,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlue, width: 2.0),
                    ),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: DropdownButtonFormField<String>(
                  value: _gareSelectionnee,
                  items: listeDesGares.map((gare) {
                    return DropdownMenuItem<String>(
                      value: gare,
                      child: Text(
                        gare,
                        style:
                            const TextStyle(color: Colors.white), // Texte blanc
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gareSelectionnee = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Gare',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white), // Contour blanc
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlue, width: 2.0),
                    ),
                  ),
                  dropdownColor: Colors.blueGrey, // Fond de la liste déroulante
                  iconEnabledColor: Colors.white, // Couleur de l'icône
                  style:
                      const TextStyle(color: Colors.white), // Texte sélectionné
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Config.colors.bleuFonce2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    onPressed: _isLoading ? null : _envoyerCodeDeVerification,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'Envoi en cours...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Recevoir un code de vérification par SMS',
                            style: TextStyle(color: Colors.white),
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
}

//::::::::::::::::::::::::::::::::::::::::

class PageDeVerification extends StatefulWidget {
  final String verificationId;
  final String nom;
  final String prenoms;
  final String telephone;
  final String ville;
  const PageDeVerification({
    super.key,
    required this.verificationId,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.ville,
  });

  @override
  _PageDeVerificationState createState() => _PageDeVerificationState();
}

class _PageDeVerificationState extends State<PageDeVerification> {
  final TextEditingController _codeController = TextEditingController();
  String idAuth = '';
  bool _isDisposed = false;
  bool _isLoading = false;
  MySqlConnection? conn;

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _connectToDatabase() async {
    conn = await Connexion.connexionDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.jauneBlanc,
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: const Text(
          'Code de vérification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(100.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  maxLength: 6,
                  cursorColor: Colors.white,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    labelText: 'Code de vérification',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isLoading || _codeController.text.isEmpty
                      ? null
                      : () {
                          _seConnecterParNumTelephone(
                              widget.verificationId, _codeController.text);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.colors.bleuFonce2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Valider',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Future<void> _seConnecterParNumTelephone(
      String verificationId, String smsCode) async {
    if (_isDisposed) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      // Mise à jour du nom d'affichage
      await user!.updateDisplayName('${widget.nom} ${widget.prenoms}');

      // Mise à jour du numéro de téléphone
      final PhoneAuthCredential phoneAuthCredential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await user.updatePhoneNumber(phoneAuthCredential);

      setState(() {
        idAuth = user.uid;
      });

      // Appel de la fonction creerUtilisateurEtAuthentifierParMail avec idAuth
      creerUtilisateurEtAuthentifierParMail(
          idAuth, widget.nom, widget.prenoms, widget.telephone, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la connexion...'),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> creerUtilisateurEtAuthentifierParMail(
    String authUid,
    String nom,
    String prenoms,
    String telephone,
    BuildContext context,
  ) async {
    try {
      // Créer l'utilisateur avec l'adresse e-mail et le mot de passe
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: "$telephone@gmail.com",
        password: telephone,
      );

      // Mettre à jour le profil de l'utilisateur avec les informations supplémentaires
      User? user = userCredential.user;
      if (user != null) {
        // Mettre à jour le nom d'affichage de l'utilisateur
        await user.updateDisplayName('$nom $prenoms');
        // Ajouter à la collection 'utilisateurs' dans Firestore
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .set({
          'id': user.uid,
          'idAuth': authUid,
          'nom': widget.nom,
          'prenoms': widget.prenoms,
          'gare': widget.ville,
          'telephone': widget.telephone,
          'mail': "${widget.telephone}@gmail.com",
          'dateDeCreation': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Ajouter à la collection 'utilisateurs' dans Firestore
        await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .set({
          'id': user.uid,
          'idAuth': authUid,
          'nom': widget.nom,
          'prenoms': widget.prenoms,
          'gare': widget.ville,
          'telephone': widget.telephone,
          'points': 3,
          'mail': "${widget.telephone}@gmail.com",
          'dateDeCreation': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Ajouter à MySQL
        await ajouterUtilisateurDansMySQL(
            conn ??= await Connexion.connexionDB(),
            idUtilisateur: user.uid,
            idAuth: '',
            nom: "${widget.nom} ${widget.prenoms}",
            gare: widget.ville,
            telephone: widget.telephone,
            mail: "${widget.telephone}@gmail.com");

        // Deconnexion et Reconnexion automatique une fois que l'utilisateur est créé et authentifié avec succès
        deconnexionEtReconnexion("$telephone@gmail.com", telephone);
        // Rediriger vers la page Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Accueil(),
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs
    }
  }

  Future<void> ajouterUtilisateurDansMySQL(
    MySqlConnection conn, {
    required String idUtilisateur,
    required String idAuth,
    required String nom,
    required String gare,
    required String telephone,
    required String mail,
  }) async {
    try {
      final query = '''
      INSERT INTO Admins (
        idUtilisateur, idAuth, nom, gare, telephone, mail, dateDeCreation
      ) VALUES (?, ?, ?, ?, ?, ?, NOW())
      ON DUPLICATE KEY UPDATE
        idAuth = VALUES(idAuth),
        nom = VALUES(nom),
        gare = VALUES(gare),
        telephone = VALUES(telephone),
        mail = VALUES(mail);
    ''';

      await conn.query(query, [
        idUtilisateur,
        idAuth,
        nom,
        gare,
        telephone,
        mail,
      ]);
    } catch (e) {}
  }
}

Future<void> deconnexionEtReconnexion(String email, String motDepass) async {
  try {
    // Déconnexion de l'utilisateur actuel
    await FirebaseAuth.instance.signOut();

    // Connexion avec l'e-mail et le mot de passe
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: motDepass,
    );
    // ignore: empty_catches
  } catch (e) {}
}
