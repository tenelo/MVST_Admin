import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/ajoutDimages.dart';
import 'package:mvst_admin/screens/heuresDeparts.dart';
import 'package:mvst_admin/screens/infosGare.dart';
import 'package:mvst_admin/screens/prixTickets.dart';

// ignore: must_be_immutable
class Parametres extends StatelessWidget {
  Parametres({super.key});
  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: ListView(children: [
          Column(
            children: [
              const SizedBox(
                height: 25,
              ),
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
                    "HEURE DEPART",
                    style: TextStyle(
                      fontSize: 16,
                      color: Config.colors.bleuClaire,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
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
              const SizedBox(
                height: 8,
              ),
              /* INFORMATIONS SUR LES GARES*/

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
                        builder: (context) => Informations(),
                      ),
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
              const SizedBox(
                height: 8,
              ),
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
                        builder: (context) => ListeImages(),
                      ),
                    );
                  },
                  child: Text(
                    "LES IMAGES",
                    style: TextStyle(
                      fontSize: 16,
                      color: Config.colors.bleuClaire,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
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
              )
            ],
          )
        ]),
      ),
      persistentFooterButtons: [
        Text(
          user!.displayName!,
          style: TextStyle(
            fontFamily: 'Lobster',
            color: Config.colors.bleuClaire,
          ),
        )
      ],
    );
  }
}
