import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/ajoutDimages.dart';
import 'package:mvst_admin/screens/gare.dart';
import 'package:mvst_admin/screens/heuresDeparts.dart';
import 'package:mvst_admin/screens/infosGare.dart';
import 'package:mvst_admin/screens/lignesStandard.dart';
import 'package:mvst_admin/screens/prixTickets.dart';
import 'package:mvst_admin/screens/vip/heureDepartVip.dart';
import 'package:mvst_admin/screens/vip/lignesVip.dart';
import 'package:mvst_admin/screens/vip/prixTicketsVip.dart';

// Corps réutilisable (embarqué dans le bottom nav ou dans Parametres standalone)
class ParametresBody extends StatelessWidget {
  const ParametresBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView(
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Gares()),
                      );
                    },
                    child: Text(
                      "GARES",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HeureDepart(),
                        ),
                      );
                    },
                    child: Text(
                      "HEURES DE DEPART",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 57, 57, 240),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                        side: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HeureDepartVip(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'HEURES DE DEPART VIP',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrixTickets(),
                        ),
                      );
                    },
                    child: Text(
                      "PRIX DES TICKETS",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 57, 57, 240),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                        side: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrixTicketsVip(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'PRIX DES TICKETS VIP',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LignesStandard(),
                        ),
                      );
                    },
                    child: Text(
                      "CRÉATION DE LIGNES STANDARD",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 57, 57, 240),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                        side: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LignesVip(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'CRÉATION DE LIGNES VIP',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Informations()),
                      );
                    },
                    child: Text(
                      "INFORMATIONS SUR LES GARES",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListeImages()),
                      );
                    },
                    child: Text(
                      "GESTION DES IMAGES",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .85,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "LES NOTIFICATIONS",
                      style: TextStyle(
                        fontSize: 16,
                        color: Config.colors.bleuClaire,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class Parametres extends StatelessWidget {
  Parametres({super.key});
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
        title: Text(
          "Paramètres",
          style: TextStyle(color: Config.colors.authCardBackground),
        ),
        centerTitle: true,
      ),
      body: const ParametresBody(),
      persistentFooterButtons: [
        Text(
          user?.displayName ?? '',
          style: TextStyle(
            fontFamily: 'Lobster',
            color: Config.colors.bleuClaire,
          ),
        ),
      ],
    );
  }
}
