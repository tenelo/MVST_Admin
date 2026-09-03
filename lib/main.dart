import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/authentification/connection.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/firebase_options.dart';
import 'package:mvst_admin/graphiques/diagrammeABarres.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/qrcode/lecteurQrCode.dart';
import 'package:mvst_admin/screens/placesOcuppees.dart';
import 'package:mvst_admin/screens/tousLesPassagers.dart';
import 'package:mvst_admin/parametres/parametres.dart';
import 'package:mvst_admin/screens/ticketsDuJourScannes.dart';
import 'package:mvst_admin/screens/departsDuJour.dart';
import 'package:mvst_admin/screens/profil.dart';
import 'package:mvst_admin/parametres/suppression/suppression.dart';
import 'package:mvst_admin/screens/tousLesTickets.dart';
import 'package:mvst_admin/screens/suggestions_admin.dart';
import 'package:mvst_admin/screens/synthese_du_jour.dart';
import 'package:mvst_admin/screens/vue_par_depart.dart';
import 'package:mvst_admin/gestionUtilisateurs/comptesBloques.dart';
import 'package:mvst_admin/gestionUtilisateurs/listeDesUtilisateurs.dart';
import 'package:mvst_admin/verifTickets/verifierticket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mvst_admin/parametres/gestion_admins.dart';
import 'package:mvst_admin/authentification/login_wrapper.dart';
import 'package:mvst_admin/services/auth_service.dart';

DateTime? dateActuelle = DateTime.now();

DateTime aujourdhui = DateTime(
  dateActuelle!.year,
  dateActuelle!.month,
  dateActuelle!.day,
);
DateTime dateDeDemain = aujourdhui.add(Duration(days: 1));
DateTime dateApresDemain = aujourdhui.add(Duration(days: 2));
DateTime dateDhier = aujourdhui.subtract(Duration(days: 1));
////////////
var idDate = DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(aujourdhui);
var idMoisAnnee = DateFormat('MMMM_y', 'fr_FR').format(aujourdhui);
var idAnnee = DateFormat('y', 'fr_FR').format(aujourdhui);
var dateAujourdhui = DateFormat('yyyy-MM-dd', 'fr_FR').format(aujourdhui);
var dateDApresDemain = DateFormat(
  'yyyy-MM-dd',
  'fr_FR',
).format(dateApresDemain);
/////////////////
var dateNormaleHiere = DateFormat('EEEE d MMMM y', 'fr_FR').format(dateDhier);
var dateNormale = DateFormat('EEEE d MMMM y', 'fr_FR').format(aujourdhui);
var dateNormaleDemain = DateFormat(
  'EEEE d MMMM y',
  'fr_FR',
).format(dateDeDemain);
var dateNormaleApresdemain = DateFormat(
  'EEEE d MMMM y',
  'fr_FR',
).format(dateApresDemain);

// Formater les dates
String formatLong = 'EEEE d MMMM y'; // Exemple : jeudi 2 janvier 2025
String dateAujourdhuistr = DateFormat(formatLong).format(aujourdhui);
String dateDeDemainStr = DateFormat(formatLong).format(dateDeDemain);
String dateApresDemainStr = DateFormat(formatLong).format(dateApresDemain);
String dateDhierStr = DateFormat(formatLong).format(dateDhier);

String? profil;
int? tailleEcran;
double? taille;
String? gare;
String? uid;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final String gareAdmin = prefs.getString('gare') ?? '';
  final String profilAdmin = prefs.getString('profil') ?? 'admin';
  listeDesTicketsScannes = await ListesDesTickets.ticketsAscanner(
    gareAdmin,
    profilAdmin,
  );
  runApp(const MyApp());
}

/// Decide l'ecran de demarrage : token Sanctum present -> connecte.
Future<bool> _decideDemarrage() async {
  await AuthService.chargerDepuisStorage();
  return AuthService.estConnecte();
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
      supportedLocales: const [Locale('fr', '')],
      home: FutureBuilder<bool>(
        future: _decideDemarrage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data! ? const Accueil() : const LoginWrapper();
        },
      ),
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
  int _selectedIndex = 0;
  String? _gare;
  String? _uid;
  String? _role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final idUtilisateur = AuthService.getUid();
    if (idUtilisateur == null) return;
    final gare = await recupererGare(idUtilisateur);
    final role = await recupererRole();
    if (mounted) {
      setState(() {
        _uid = idUtilisateur;
        _gare = gare;
        _role = role;
      });
    }
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
    final c = Config.colors;
    return Stack(
      children: [
        Scaffold(
          appBar: _selectedIndex == 0
              ? AppBar(
                  iconTheme: IconThemeData(color: c.jauneBlanc),
                  backgroundColor: c.authCardBackground,
                  title: Text(
                    'CONTROLEURS MVST',
                    style: TextStyle(
                      color: c.jauneBlanc,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  centerTitle: true,
                )
              : null,
          bottomNavigationBar: _BottomNav(
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
          drawer: Drawer(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(color: c.authCardBackground),
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
                                    color: c.jauneBlanc,
                                    width: 2.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'MVST',
                                    style: TextStyle(
                                      color: c.jauneBlanc,
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
                          color: c.bleuClaire,
                        ),
                        title: Text(
                          'Profil',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () async {
                          if (AuthService.estConnecte()) {
                            String userId = AuthService.getUid() ?? '';
                            String userProfil =
                                await recupererRole() ?? 'admin';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profil(
                                  idUtilisateur: userId,
                                  userProfil: userProfil,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.settings_outlined,
                          color: c.bleuClaire,
                        ),
                        title: Text(
                          'Parametres',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () {
                          if (AuthService.estConnecte()) {
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
                        leading: Icon(Icons.search, color: c.bleuClaire),
                        title: Text(
                          'Vérifications de tickets',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () {
                          if (AuthService.estConnecte()) {
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

                      //  Visible uniquement pour superadmin
                      if (_role == 'superadmin')
                        ListTile(
                          leading: Icon(
                            Icons.admin_panel_settings_outlined,
                            color: c.bleuClaire,
                          ),
                          title: Text(
                            'Gestion des Admins',
                            style: TextStyle(
                              color: c.bleuClaire,
                              fontFamily: 'Lobster',
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GestionAdmins(),
                              ),
                            );
                          },
                        ),
                      ListTile(
                        leading: Icon(
                          Icons.people_alt_outlined,
                          color: c.bleuClaire,
                        ),
                        title: Text(
                          'Utilisateurs',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () {
                          if (AuthService.estConnecte()) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ListeDesUtilisateurs(),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                            showIncompleteFieldsSnackBar(context);
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.block_rounded, color: c.bleuClaire),
                        title: Text(
                          'Comptes bloqués',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () {
                          if (AuthService.estConnecte()) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GestionComptesBloques(),
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
                          Icons.delete_forever_outlined,
                          color: Colors.red[300],
                        ),
                        title: Text(
                          'Supprimer ticket',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () {
                          if (AuthService.estConnecte()) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Suppression(
                                  dateHier: dateNormaleHiere,
                                  aujoudhui: dateNormale,
                                  demain: dateNormaleDemain,
                                  apresDemain: dateNormaleApresdemain,
                                ),
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
                          color: c.bleuClaire,
                        ),
                        title: Text(
                          'Déconnexion',
                          style: TextStyle(
                            color: c.bleuClaire,
                            fontFamily: 'Lobster',
                          ),
                        ),
                        onTap: () => deconnexion(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.25,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    scannQrCode(context, setLoadingState),
                    ticketsScannes(context, setLoadingState),
                    departsDuJour(context, setLoadingState),
                    placesOccupees(context, setLoadingState),
                    suggestions(context, setLoadingState),
                    syntheseDuJour(context, setLoadingState),
                    vueParDepart(context, setLoadingState),
                  ],
                ),
              ),
              _gare != null && _uid != null
                  ? GraphiquesABarres(
                      gare: _gare!,
                      uid: _uid!,
                      date: idDate,
                      moisAnnee: idMoisAnnee,
                      annee: idAnnee,
                    )
                  : const Center(child: CircularProgressIndicator()),
              _gare != null && _uid != null
                  ? TousLesTickets(gare: _gare!, uid: _uid!, date: idAnnee)
                  : const Center(child: CircularProgressIndicator()),
              _gare != null && _gare!.isNotEmpty && _uid != null
                  ? TousLesPassagers(
                      gare: _gare!,
                      uid: _uid!,
                      date: idDate,
                      dateNormale: dateNormale,
                      tailleEcran: tailleEcran!,
                    )
                  : const Center(child: CircularProgressIndicator()),
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
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Bottom nav  ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Graphiques',
    ),
    (
      icon: Icons.table_chart_outlined,
      activeIcon: Icons.table_chart,
      label: 'Tickets',
    ),
    (icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Passagers'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < _items.length; i++)
            Expanded(
              child: _NavTab(
                icon: _items[i].icon,
                activeIcon: _items[i].activeIcon,
                label: _items[i].label,
                selected: selectedIndex == i,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Config.colors.jauneBlanc : Colors.white54;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              selected ? activeIcon : icon,
              key: ValueKey(selected),
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 24 : 0,
            decoration: BoxDecoration(
              color: Config.colors.jauneBlanc,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper carte commune ──────────────────────────────────────────────────────
Widget _carteMenu({
  required BuildContext ctx,
  required Function setLoadingState,
  required Future<void> Function() onTap,
  required IconData icon,
  required String label,
  Color? iconColor,
}) {
  final c = Config.colors;
  final color = iconColor ?? c.couleurIcone;
  return GestureDetector(
    onTap: () async {
      setLoadingState(true);
      await onTap();
    },
    child: Card(
      //color: Colors.white,
      shadowColor: c.couleurOmbreCarte,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: color),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                // color: Colors.black87,
                color: c.couleurIcone,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget scannQrCode(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.qr_code_scanner_outlined,
    label: 'SCANNER LES TICKETS',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        final String profilAdmin = await recupererRole() ?? 'admin';
        await ListesDesTickets.ticketsAscanner(_gare ?? '', profilAdmin);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => LecteurQrCode(
              gare: _gare!,
              uid: _uid,
              dateNormale: dateNormale,
              dateAujourdhui: dateAujourdhui,
              dateApresDemain: dateDApresDemain,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget ticketsScannes(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: CupertinoIcons.tickets,
    label: 'TICKETS SCANNÉS',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) =>
                TicketsDuJourScannes(gare: _gare!, uid: _uid, date: idDate),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget graphiques(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.bar_chart_outlined,
    label: 'GRAPHIQUES',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => GraphiquesABarres(
              gare: _gare!,
              uid: _uid,
              date: idDate,
              moisAnnee: idMoisAnnee,
              annee: idAnnee,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget departsDuJour(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.bar_chart,
    label: 'DÉPARTS DU JOUR',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => DepartsDuJour(
              gare: _gare!,
              uid: _uid,
              date: idDate,
              dateNormale: dateNormale,
              tailleEcran: tailleEcran!,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget tableau(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.format_list_bulleted_sharp,
    label: 'Tous les Tickets',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) =>
                TousLesTickets(gare: _gare!, uid: _uid, date: idAnnee),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget placesOccupees(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.event_seat,
    label: 'PLACES OCCUPÉES',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => PlacesOccupees(
              gare: _gare!,
              uid: _uid,
              date: idDate,
              dateNormale: dateNormale,
              tailleEcran: tailleEcran!,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget listePassagers(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.format_list_bulleted,
    label: 'LISTE DES PASSAGERS',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final String? _gare = await recupererGare(_uid);
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => TousLesPassagers(
              gare: _gare!,
              uid: _uid,
              date: idDate,
              dateNormale: dateNormale,
              tailleEcran: tailleEcran!,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget suppressionTickets(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.delete_forever_outlined,
    label: 'SUPPRIMER TICKET',
    iconColor: Colors.red[300]!,
    onTap: () async {
      if (AuthService.estConnecte()) {
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => Suppression(
              dateHier: dateNormaleHiere,
              aujoudhui: dateNormale,
              demain: dateNormaleDemain,
              apresDemain: dateNormaleApresdemain,
            ),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget listeUtilisateurs(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.people_alt_outlined,
    label: 'UTILISATEURS',
    onTap: () async {
      if (AuthService.estConnecte()) {
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const ListeDesUtilisateurs()),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget comptesBloques(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.block_rounded,
    label: 'COMPTES BLOQUÉS',
    iconColor: Colors.red[400]!,
    onTap: () async {
      if (AuthService.estConnecte()) {
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const GestionComptesBloques()),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget suggestions(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.chat_bubble_outline_rounded,
    label: 'SUGGESTIONS',
    onTap: () async {
      if (AuthService.estConnecte()) {
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const SuggestionsAdmin()),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget syntheseDuJour(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.dashboard_outlined,
    label: 'SYNTHESE DU JOUR',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final prefs = await SharedPreferences.getInstance();
        String _gare = prefs.getString('gare') ?? '';
        if (_gare.isEmpty) {
          _gare = await recupererGare(_uid) ?? '';
        }
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => SyntheseDuJour(gare: _gare, uid: _uid),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
  );
}

Widget vueParDepart(BuildContext ctx, Function setLoadingState) {
  return _carteMenu(
    ctx: ctx,
    setLoadingState: setLoadingState,
    icon: Icons.event_seat_outlined,
    label: 'VUE PAR DEPART',
    onTap: () async {
      if (AuthService.estConnecte()) {
        final String _uid = AuthService.getUid() ?? '';
        final prefs = await SharedPreferences.getInstance();
        String _gare = prefs.getString('gare') ?? '';
        if (_gare.isEmpty) {
          _gare = await recupererGare(_uid) ?? '';
        }
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => VueParDepart(gare: _gare, uid: _uid),
          ),
        ).then((_) => setLoadingState(false));
      } else {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => const Login()),
        ).then((_) => setLoadingState(false));
      }
    },
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

Future<void> deconnexion(BuildContext context) async {
  // Nettoyage complet : token Sanctum + identite locale + session
  // Firebase residuelle. AuthService.deconnexion centralise tout ca
  // (POST /logout best-effort, suppression token, purge cles, signOut).
  await AuthService.deconnexion();
  // Purge aussi les cles SharedPreferences propres a l'admin (gare/uid/
  // role) encore lues par main() et profil.dart.
  await supprimerGareEtUid();

  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const Login()),
    (route) => false,
  );
}
