// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/models/models.dart';
import 'package:mysql1/mysql1.dart';

List<PlacesTickets> maListeDeTickets = [];

class PlacesAssises extends StatefulWidget {
  const PlacesAssises(
      {super.key,
      required this.documentId,
      required this.depart,
      required this.destination,
      required this.heure});
  final String documentId;
  final String depart;
  final String destination;
  final String heure;
  @override
  State<PlacesAssises> createState() => _PlacesAssisesState();
}

class _PlacesAssisesState extends State<PlacesAssises> {
  bool _isLoading = true;
  String? _errorMessage;
  MySqlConnection? conn;

  @override
  void initState() {
    super.initState();
    _connectDatabase();
    chargerDonnees();
  }

  Future<void> _connectDatabase() async {
    conn = await Connexion.connexionDB();
  }

  Future<void> chargerDonnees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      conn ??= await Connexion.connexionDB();

      // Requête pour récupérer les tickets correspondant au documentId
      var results = await conn!.query(
        'SELECT nom, telephone, depart, destination, place FROM Tickets WHERE documentId = ?',
        [widget.documentId],
      );

      // Parcourir les résultats et les ajouter à la liste d'objets
      maListeDeTickets = results.map((row) {
        return PlacesTickets(
          nom: row['nom'].toString(),
          telephone: row['telephone'].toString(),
          depart: row['depart'].toString(),
          destination: row['destination'].toString(),
          place: int.parse(row['place'].toString()),
        );
      }).toList();
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    maListeDeTickets.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      appBar: AppBar(
        toolbarHeight: 40,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${widget.heure} h",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(132, 5, 82, 121),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.amber,
            ))
          : _errorMessage != null
              ? Center(child: Text('Erreur'))
              : Container(
                  color: const Color.fromARGB(69, 191, 217, 248),
                  child: Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.80,
                      width: MediaQuery.of(context).size.width * 0.70,
                      child: Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Config.colors.jauneBlanc),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50),
                            ),
                            color: const Color.fromARGB(168, 191, 217, 248),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                // DERNIERE RANGEE
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PlacesReservees(
                                      numero: 61,
                                    ),
                                    PlacesReservees(
                                      numero: 60,
                                    ),
                                    PlacesReservees(
                                      numero: 59,
                                    ),
                                    PlacesReservees(
                                      numero: 58,
                                    ),
                                    PlacesReservees(
                                      numero: 57,
                                    ),
                                    PlacesReservees(
                                      numero: 56,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // RANGE DE 2 SIEGES
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        //col1
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 55,
                                            ),
                                            Places(
                                              numero: 54,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 50,
                                            ),
                                            Places(
                                              numero: 49,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 45,
                                            ),
                                            Places(
                                              numero: 44,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 40,
                                            ),
                                            Places(
                                              numero: 39,
                                            ),
                                          ],
                                        ),
                                        //PORTE ARRIERE
                                        porte(),
                                        const SizedBox(
                                          height: 1,
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 35,
                                            ),
                                            Places(
                                              numero: 34,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 30,
                                            ),
                                            Places(
                                              numero: 29,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 25,
                                            ),
                                            Places(
                                              numero: 24,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 20,
                                            ),
                                            Places(
                                              numero: 19,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 15,
                                            ),
                                            Places(
                                              numero: 14,
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              numero: 10,
                                            ),
                                            Places(
                                              numero: 9,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            PlacesReservees(
                                              numero: 5,
                                            ),
                                            PlacesReservees(
                                              numero: 4,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // ESPACE DU MILEIU
                                    const SizedBox(
                                      width: 35,
                                    ),
                                    // RANGE DE 3 SIEGES
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Places(
                                              numero: 53,
                                            ),
                                            Places(
                                              numero: 52,
                                            ),
                                            Places(
                                              numero: 51,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 48,
                                            ),
                                            Places(
                                              numero: 47,
                                            ),
                                            Places(
                                              numero: 46,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 43,
                                            ),
                                            Places(
                                              numero: 42,
                                            ),
                                            Places(
                                              numero: 41,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 38,
                                            ),
                                            Places(
                                              numero: 37,
                                            ),
                                            Places(
                                              numero: 36,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 33,
                                            ),
                                            Places(
                                              numero: 32,
                                            ),
                                            Places(
                                              numero: 31,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 28,
                                            ),
                                            Places(
                                              numero: 27,
                                            ),
                                            Places(
                                              numero: 26,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 23,
                                            ),
                                            Places(
                                              numero: 22,
                                            ),
                                            Places(
                                              numero: 21,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 18,
                                            ),
                                            Places(
                                              numero: 17,
                                            ),
                                            Places(
                                              numero: 16,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 13,
                                            ),
                                            Places(
                                              numero: 12,
                                            ),
                                            Places(
                                              numero: 11,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              numero: 8,
                                            ),
                                            Places(
                                              numero: 7,
                                            ),
                                            Places(
                                              numero: 6,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            PlacesReservees(
                                              numero: 3,
                                            ),
                                            PlacesReservees(
                                              numero: 2,
                                            ),
                                            PlacesReservees(
                                              numero: 1,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            SizedBox(width: 60),
                                            PlacesChauffeur(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // COLONNE DE 2
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // PORTE AVANT
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        porte(),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 150,
                                    ),
                                    // Colonne pour le volant
                                    Column(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 50,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                'assets/images/volant4_sf.png',
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class Places extends StatefulWidget {
  const Places({
    super.key,
    required this.numero,
  });
  final int numero;

  @override
  State<Places> createState() => _PlacesState();
}

class _PlacesState extends State<Places> {
  Color couleurSelection = const Color.fromARGB(255, 182, 214, 251);
  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);
  bool isLoading = false;
  String etat = "nonCliquable";

  @override
  void initState() {
    super.initState();
    verification();
  }

  void verification() {
    if (maListeDeTickets.isNotEmpty) {
      // Vérifie si un numéro de place correspond
      if (maListeDeTickets.any((ticket) => ticket.place == widget.numero)) {
        setState(() {
          couleurInitiale = couleurSelection;
          etat = "cliquable";
        });
      }
    }
  }

  Future<void> _afficherInfos() async {
    setState(() {
      isLoading = true;
    });

    // Chercher les informations du ticket en fonction du numéro de place
    var ticket = maListeDeTickets.firstWhere(
      (ticket) => ticket.place == widget.numero,
    );
    showRichTextDialog(
      context,
      ticket.nom,
      ticket.telephone,
      ticket.depart,
      ticket.destination,
      ticket.place,
    );

    setState(() {
      isLoading = false;
    });
  }

  // La liste de booléens qui représente la sélection de chaque carte
  // On crée une liste de 62 booléens
  List<bool> selection = List.filled(62, false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (etat == "cliquable") {
          setState(() {
            isLoading = true;
          });
          _afficherInfos();
          setState(() {
            isLoading = false;
          });
        }
      },
      child: Container(
        // Espaces entre les sièges
        margin: const EdgeInsets.all(0.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              // CARTE PRINCIPALE
              Card(
                color: selection[widget.numero % 62]
                    ? couleurSelection
                    : couleurInitiale,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  height: 35,
                  width: 35,
                  child: Center(
                    child: Text(
                      widget.numero.toString(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            // CARTE GAUCHE
            Positioned(
              left: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  height: 19,
                  width: 6,
                ),
              ),
            ),
            // CARTE DROITE
            Positioned(
              right: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  height: 19,
                  width: 6,
                ),
              ),
            ),
            // CARTE DU HAUT
            Positioned(
              top: -4,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  height: 6,
                  width: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showAlertDialog(BuildContext context, String nom, String telephone,
    String depart, String destination, int place) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passager : $nom'),
            Text('Téléphone : $telephone'),
            Text('Place : $place'),
            Text('Départ : $depart'),
            Text('Destination : $destination'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showRichTextDialog(BuildContext context, String nom, String telephone,
    String depart, String destination, int place) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(
          child: Text(
            '$depart -> $destination',
            style: TextStyle(
              color: Color.fromARGB(255, 4, 20, 243),
              fontSize: 18,
            ),
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
            children: [
              const TextSpan(
                text: 'Passager : ',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextSpan(
                  text: '$nom\n', style: const TextStyle(color: Colors.black)),
              const TextSpan(
                text: 'Téléphone : ',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextSpan(
                  text: '$telephone\n',
                  style: const TextStyle(color: Colors.black)),
              const TextSpan(
                text: 'Place :    ',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextSpan(
                text: '$place',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 4, 20, 243),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'OK',
              style: TextStyle(color: Color.fromARGB(255, 4, 20, 243)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// ignore: must_be_immutable
class PlacesReservees extends StatelessWidget {
  PlacesReservees({super.key, required this.numero});
  final int numero;
  Color couleurSelection = Color.fromARGB(166, 249, 195, 115);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Espaces entre les sièges
      margin: const EdgeInsets.all(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CARTE PRINCIPALE
          Card(
            color: couleurSelection,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: 35,
              width: 35,
              child: Center(
                child: Text(
                  numero.toString(),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // CARTE GAUCHE
          Positioned(
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ), // CARTE DROITE
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ),
          //CARTE DU HAUT
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 6,
                width: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class PlacesChauffeur extends StatelessWidget {
  PlacesChauffeur({
    super.key,
  });

  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Espaces entre les sièges
      margin: const EdgeInsets.all(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CARTE PRINCIPALE
          Card(
            color: Config.colors.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              height: 35,
              width: 35,
              child: Center(
                child: Text(
                  (""), // On convertit l'numero en chaîne de caractères
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // CARTE GAUCHE
          Positioned(
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ), // CARTE DROITE
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ),
          //CARTE DU HAUT
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 6,
                width: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
