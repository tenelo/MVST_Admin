import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/authentification/authentification.dart';
import 'package:mvst_admin/authentification/connection.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/firebase_options.dart';
import 'package:mvst_admin/graphiques/diagrammeABarres.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/qrcode/lecteurQrCode.dart';
import 'package:mvst_admin/screens/listeTicketsScannes.dart';
import 'package:mvst_admin/screens/parametres.dart';
import 'package:mvst_admin/screens/profil.dart';
import 'package:mvst_admin/screens/tableaudestickets.dart';
import 'package:mvst_admin/verifTickets/verifierticket.dart';

DateTime? dateActuelle = DateTime.now();
DateTime? aujourdhui =
    DateTime.utc(dateActuelle!.year, dateActuelle!.month, dateActuelle!.day);
var idDate = DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(aujourdhui!);
var idMoisAnnee = DateFormat('MMMM_y', 'fr_FR').format(aujourdhui!);
var idAnnee = DateFormat('y', 'fr_FR').format(aujourdhui!);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialiser les données de localisation pour 'fr_FR'
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
  ListeDesId.getTicketsAScanner(idDate);
  listenForTicketChanges();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ListeDesId.getTicketsAScanner(idDate);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Config.colors.bleuFonce),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
      ],
      home: const Accueil(),
    );
  }
}

class Accueil extends StatefulWidget {
  const Accueil({super.key});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ListeDesId.getTicketsAScanner(idDate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Vider la liste lorsque l'application est en arrière-plan ou fermée
      monTicket.clear();
    }
  }

  bool isLoading = false;
  void setLoadingState(bool state) {
    setState(() {
      isLoading = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.colors.jauneBlanc,
        title: const Text(
          'CONTROLEURS MVST',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Config.colors.bleuFonce2,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120.0,
                            height: 120.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Config.colors.jauneBlanc,
                                width: 2.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'MVST',
                                style: TextStyle(
                                  color: Config.colors.bleuClaire,
                                  fontSize: 24,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.perm_identity_outlined,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Profil',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser != null) {
                        String userId = FirebaseAuth.instance.currentUser!.uid;
                        String? userProfil =
                            FirebaseAuth.instance.currentUser!.displayName;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profil(
                              idUtilisateur: userId,
                              userProfil: userProfil!,
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PageDAuthentification(),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Parametres',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Parametres(),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                        showIncompleteFieldsSnackBar(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.search,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Vérifications de tickets',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParametresVerification(),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                        showIncompleteFieldsSnackBar(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.power_settings_new,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () => deconnexion(context),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.info_outlined,
                color: Config.colors.bleuClaire,
              ),
              title: Text(
                'À propos du développeur',
                style: TextStyle(
                  color: Config.colors.bleuClaire,
                  fontFamily: 'Lobster',
                ),
              ),
              onTap: () {
                if (FirebaseAuth.instance.currentUser != null) {
                } else {
                  Navigator.pop(context);
                  showIncompleteFieldsSnackBar(context);
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  scannQrCode(context, setLoadingState),
                  ticketsScannes(context, setLoadingState),
                  graphiques(context, setLoadingState),
                  tableau(context, setLoadingState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget scannQrCode(BuildContext ctx, Function setLoadingState) {
  return GestureDetector(
    onTap: () async {
      setLoadingState(true);
      await ListeDesId.getTicketsAScanner(idDate);
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (BuildContext context) => const LecteurQrCode()));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
      setLoadingState(false);
    },
    child: Card(
      shadowColor: Colors.blue,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                Icons.qr_code_scanner_outlined,
                size: 60,
              ),
            ),
            Text("SCANNER LES TICKETS")
          ],
        ),
      ),
    ),
  );
}

Widget ticketsScannes(BuildContext ctx, Function setLoadingState) {
  return GestureDetector(
    onTap: () async {
      setLoadingState(true);
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (BuildContext context) => MesTickets(
                      date: idDate,
                      idUtilisateur: userId,
                    )));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
      setLoadingState(false);
    },
    child: Card(
      shadowColor: Colors.blue,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                CupertinoIcons.tickets,
                size: 60,
              ),
            ),
            Text("TICKETS SCANNES")
          ],
        ),
      ),
    ),
  );
}

Widget graphiques(BuildContext ctx, Function setLoadingState) {
  return GestureDetector(
    onTap: () async {
      setLoadingState(true);
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (BuildContext context) => GraphiquesABarres(
              date: idDate,
              moisAnnee: idMoisAnnee,
              annee: idAnnee,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
      setLoadingState(false);
    },
    child: Card(
      shadowColor: Colors.blue,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                Icons.bar_chart_outlined,
                size: 60,
              ),
            ),
            Text("GRAPHIQUES")
          ],
        ),
      ),
    ),
  );
}

Widget tableau(BuildContext ctx, Function setLoadingState) {
  return GestureDetector(
    onTap: () async {
      setLoadingState(true);
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;

        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (context) => TableauDeTickets(
              date: idAnnee,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const PageDAuthentification(),
          ),
        );
      }
      setLoadingState(false);
    },
    child: Card(
      shadowColor: Colors.blue,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                Icons.table_rows_outlined,
                size: 60,
              ),
            ),
            Text(
              "TABLEAU DE TICKETS",
            ),
          ],
        ),
      ),
    ),
  );
}

void showIncompleteFieldsSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      duration: Duration(seconds: 8),
      backgroundColor: Color.fromARGB(255, 241, 94, 94),
      content: Text(
        'Vous n\'êtes pas authentifié, allez dans Paramètres puis Profil pour créer votre compte',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

void deconnexion(BuildContext context) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  await _auth.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (BuildContext context) => const Login()),
    (route) => false,
  );
}

// MAIN AVEC BLOC 
/*

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ListeDesId.getTicketsAScanner(idDate);
    return BlocProvider(
      create: (context) => BlocListePlaces()..add(ChargerLaList()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Config.colors.bleuFonce),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
        ],
        home: const Accueil(),
      ),
    );
  }
}


*/