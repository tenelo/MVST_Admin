import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst_admin/authentification/authentification.dart';
import 'package:mvst_admin/authentification/connection.dart';
import 'package:mvst_admin/bloc/bolc.dart';
import 'package:mvst_admin/bloc/event.dart';
import 'package:mvst_admin/bloc/exempleAffichage2.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/firebase_options.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/qrcode/lecteurQrCode.dart';
import 'package:mvst_admin/screens/parametres.dart';
import 'package:mvst_admin/screens/profil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
  listenForTicketChanges();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BlocListePlaces()..add(ChargerLaList()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Config.colors.bleuFonce),
          useMaterial3: true,
        ),
        home: const Accueil(),
      ),
    );
  }
}

class Accueil extends StatefulWidget {
  const Accueil({super.key});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.colors.jauneBlanc,
        title: const Text(
          'ADMINISTRATEURS MVST',
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
                      child: Container(
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
                  scannQrCode(context),
                  achatDeTicket(context),
                  tableauDeBord(context),
                  impression(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Color.fromARGB(255, 119, 156, 172),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            label: 'Mes Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Infos',
          ),
        ],
      ),
    );
  }
}

Widget scannQrCode(BuildContext ctx) {
  return GestureDetector(
    onTap: () {
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

Widget achatDeTicket(BuildContext ctx) {
  return GestureDetector(
    onTap: () {
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      }
      /*
      Navigator.push(
          ctx,
          MaterialPageRoute(
              builder: (BuildContext context) => const HomeAdmin()));
    */
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
            Text("ACHAT DE TICKETS")
          ],
        ),
      ),
    ),
  );
}

Widget tableauDeBord(BuildContext ctx) {
  return GestureDetector(
    onTap: () {
      FonctionListeDesPlaces.recup();
      //ClasseListeDesPlaces.getTicketsStream();
      BlocProvider.of<BlocListePlaces>(ctx).add(ChargerLaList());
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (context) => SecondPage(),
        ),
      );
      /*
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;

        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (context) => IntegerListPage1(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const PageDAuthentification(),
          ),
        );
      }*/
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
            Text("TABLEAU DE BORD")
          ],
        ),
      ),
    ),
  );
}

Widget impression(BuildContext ctx) {
  return GestureDetector(
    onTap: () {
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String? userProfil = FirebaseAuth.instance.currentUser!.displayName;

        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (context) => SecondPage(),
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
                Icons.file_copy_outlined,
                size: 60,
              ),
            ),
            Text("IMPRIMER RECUS")
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

/*

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BlocCompteur>(
          create: (context) => BlocCompteur(),
        ),
        BlocProvider<BlocAjoutListe>(
          create: (context) => BlocAjoutListe(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Config.colors.bleuFonce),
          useMaterial3: true,
        ),
        // Mettre la date en Français
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
        ],

        home: Accueil(),
      ),
    );
  }
}


*/
