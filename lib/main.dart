import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/authentification/authentification.dart';
import 'package:mvst_admin/authentification/connection.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/firebase_options.dart';
import 'package:mvst_admin/graphiques/diagrammeABarres.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/qrcode/lecteurQrCode.dart';
import 'package:mvst_admin/screens/menulateral.dart';
import 'package:mvst_admin/screens/parametres.dart';
import 'package:mvst_admin/screens/profil.dart';
import 'package:mvst_admin/screens/tableaudestickets.dart';
import 'package:mvst_admin/verifTickets/verifierticket.dart';

DateTime? dateActuelle = DateTime.now();
DateTime? aujourdhui =
    DateTime.utc(dateActuelle!.year, dateActuelle!.month, dateActuelle!.day);
DateTime? dateDeDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 1);
DateTime? dateApresDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 2);
////////////
var idDate = DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(aujourdhui!);
var idMoisAnnee = DateFormat('MMMM_y', 'fr_FR').format(aujourdhui!);
var idAnnee = DateFormat('y', 'fr_FR').format(aujourdhui!);
var dateAujourdhui = DateFormat('yyyy-MM-dd', 'fr_FR').format(aujourdhui!);
var dateDApresDemain =
    DateFormat('yyyy-MM-dd', 'fr_FR').format(dateApresDemain!);
/////////////////
var dateNormale = DateFormat('EEEE d MMMM y', 'fr_FR').format(aujourdhui!);
var dateNormaleDemain =
    DateFormat('EEEE d MMMM y', 'fr_FR').format(dateDeDemain!);
var dateNormaleApresdemain =
    DateFormat('EEEE d MMMM y', 'fr_FR').format(dateApresDemain!);

User? user;
int? tailleEcran;
double? taille;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Désactive la rotation de l'écran en mode paysage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialiser les données de localisation pour 'fr_FR'
  await initializeDateFormatting('fr_FR', null);
  listeDesTicketsScannes = await ListesDesTickets.ticketsAscanner();
  runApp(const MyApp());

  listenForTicketChanges();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    tailleEcran = Calcule.tailleEcran(context).round();
    return MaterialApp(
      title: 'MVST Admin',
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  void setLoadingState(bool state) {
    setState(() {
      isLoading = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                            String userId =
                                FirebaseAuth.instance.currentUser!.uid;
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
                                builder: (context) =>
                                    const PageDAuthentification(),
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
                const SizedBox(
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
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: Config.colors.jauneBlanc,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            spacing: 10,
            spaceBetweenChildren: 10,
            children: [
              SpeedDialChild(
                //backgroundColor: Config.colors.jauneBlanc,
                child: Icon(
                  Icons.format_list_bulleted,
                  color: Config.colors.bleuA,
                  size: 30,
                ),
                label: 'Liste des passagers',
                labelStyle: TextStyle(
                  fontSize: 16.0,
                  color: Config.colors.bleuA,
                  fontWeight: FontWeight.bold,
                ),
                onTap: () => {},
              ),
              SpeedDialChild(
                //backgroundColor: Config.colors.jauneBlanc,
                child: Icon(
                  Icons.event_seat,
                  color: Config.colors.bleuA,
                  size: 30,
                ),
                label: 'Places occupées',
                labelStyle: TextStyle(
                  fontSize: 16.0,
                  color: Config.colors.bleuA,
                  fontWeight: FontWeight.bold,
                ),
                onTap: () => {},
              ),
            ],
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget scannQrCode(BuildContext ctx, Function setLoadingState) {
  return GestureDetector(
    onTap: () async {
      setLoadingState(true);

      await ListesDesTickets.ticketsAscanner();

      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (BuildContext context) => LecteurQrCode(
              dateNormale: dateNormale,
              dateAujourdhui: dateAujourdhui,
              dateApresDemain: dateDApresDemain,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        ).then((_) => setLoadingState(false));
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
          children: const [
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
        user = FirebaseAuth.instance.currentUser;
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (BuildContext context) => MenuLateral(
              tailleEcran: tailleEcran!,
              date: idDate,
              dateNormale: dateNormale,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        ).then((_) => setLoadingState(false));
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
          children: const [
            SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                CupertinoIcons.tickets,
                size: 60,
              ),
            ),
            Text("TICKETS SCANNÉS")
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
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (BuildContext context) => GraphiquesABarres(
            date: idDate,
            moisAnnee: idMoisAnnee,
            annee: idAnnee,
          ),
        ),
      ).then((_) => setLoadingState(false));
    },
    child: Card(
      shadowColor: Colors.blue,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
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
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (BuildContext context) => TableauDeTickets(
            date: idAnnee,
          ),
        ),
      ).then((_) => setLoadingState(false));
    },
    child: Card(
      shadowColor: Colors.blue,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                Icons.format_list_bulleted_sharp,
                size: 60,
              ),
            ),
            Text("TABLEAU")
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
