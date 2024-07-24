import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:mvst_admin/screens/petitsEcrans/detailsTickets2.dart';
import 'package:ticket_material/ticket_material.dart';

int? tailleEcran;

class MesTickets extends StatefulWidget {
  const MesTickets({
    super.key,
    required this.date,
    required this.idUtilisateur,
  });
  final String date;
  final String idUtilisateur;
  @override
  State<MesTickets> createState() => _MesTicketsState();
}

class _MesTicketsState extends State<MesTickets> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>>
      recuperationDeMesTickets() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .where('dateDeDepart', isEqualTo: widget.date)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((ticketsSnapshot) async {
      List<DocumentSnapshot<Map<String, dynamic>>> allDocuments = [];
      for (var ticketDoc in ticketsSnapshot.docs) {
        try {
          var subcollectionSnapshot = await ticketDoc.reference
              .collection('sousCollectionTickets')
              .where('etatScanne', isEqualTo: 'scanné')
              .orderBy('heureDeScanne', descending: true)
              .get();
          allDocuments.addAll(subcollectionSnapshot.docs);
        } catch (e) {
          print('Erreur de chargement du ticket ${ticketDoc.id}: $e');
        }
      }
      return allDocuments;
    });
  }

  List<DocumentSnapshot<Map<String, dynamic>>> _filterTickets(
      List<DocumentSnapshot<Map<String, dynamic>>> tickets) {
    if (_searchText.isEmpty) return tickets;

    return tickets.where((ticket) {
      final data = ticket.data();
      if (data == null) return false;
      final searchText = _searchText;
      return data['nom'].toString().toLowerCase().contains(searchText) ||
          data['telephone'].toString().toLowerCase().contains(searchText) ||
          data['date'].toString().toLowerCase().contains(searchText) ||
          data['depart'].toString().toLowerCase().contains(searchText) ||
          data['destination'].toString().toLowerCase().contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    tailleEcran = calculeTailleEcran(context).round();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: TextStyle(
                color: Colors.grey[600]), // Couleur du texte de l'indice
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0), // Bordure arrondie
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0), // Bordure arrondie
              borderSide: BorderSide(
                  color: Colors.blueAccent,
                  width: 2.0), // Couleur et épaisseur de la bordure
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0), // Bordure arrondie
              borderSide: BorderSide(
                  color: Colors.blue,
                  width:
                      2.0), // Couleur et épaisseur de la bordure lorsque le champ est focus
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 10.0), // Espacement interne
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
            stream: recuperationDeMesTickets(),
            builder: (BuildContext context,
                AsyncSnapshot<List<DocumentSnapshot<Map<String, dynamic>>>>
                    snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Erreur de chargement : ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text("Vous n'avez scanné aucun ticket",
                        style: TextStyle(
                            color: Config.colors.bleuFonce2,
                            fontWeight: FontWeight.bold)));
              }

              final filteredTickets = _filterTickets(snapshot.data!);

              return ListView.builder(
                itemCount: filteredTickets.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot<Map<String, dynamic>> document =
                      filteredTickets[index];
                  Map<String, dynamic>? ticket = document.data();
                  if (ticket == null) {
                    return Center(
                        child:
                            Text('Erreur de chargement des données du ticket'));
                  }
                  var idTicket = document.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TicketMaterial(
                      height: 115,
                      colorBackground: Color.fromARGB(108, 5, 82, 121),
                      colorShadow: Colors.white,
                      shadowSize: 2,
                      radiusBorder: 8,
                      leftChild: _buildLeft(
                        context,
                        idTicket,
                        ticket['idUtilisateur'],
                        ticket['nom'],
                        ticket['telephone'],
                        ticket['date'],
                        ticket['heure'],
                        ticket['depart'],
                        ticket['destination'],
                        ticket['place'],
                        ticket['etatScanne'],
                        ticket['prixDuTicket'].toString(),
                        ticket['statut'],
                      ),
                      rightChild: _buildRight(),
                      tapHandler: () {},
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeft(
      BuildContext context,
      String idTicket,
      String idUtilisateur,
      String nom,
      String contact,
      String date,
      String heure,
      String depart,
      String destination,
      int numeroDePlace,
      String etatScann,
      String prixTicket,
      String statut) {
    return GestureDetector(
      onTap: () {
        if (tailleEcran! >= 6) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsTickets(
                idTicket: idTicket,
                idUtilisateur: idUtilisateur,
                nom: nom,
                contact: contact,
                date: date,
                heure: heure,
                depart: depart,
                destination: destination,
                place: numeroDePlace,
                etatScann: etatScann,
                statut: statut,
                prixTicket: prixTicket,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsTickets2(
                idTicket: idTicket,
                idUtilisateur: idUtilisateur,
                nom: nom,
                contact: contact,
                date: date,
                heure: heure,
                depart: depart,
                destination: destination,
                place: numeroDePlace,
                etatScann: etatScann,
                statut: statut,
                prixTicket: prixTicket,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
          top: 8,
          right: 2,
          bottom: 2,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Départ du : ",
                  style: TextStyle(
                    decorationColor: Colors.white,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Heure de départ : ",
                  style: TextStyle(
                    decorationColor: Colors.white,
                  ),
                ),
                Text(
                  heure,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Siège : ",
                  style: TextStyle(
                    decorationColor: Colors.white,
                  ),
                ),
                Text(
                  "N° $numeroDePlace",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            const Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Center(
                child: SizedBox(
                  height: 32,
                  child: TextButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: const BorderSide(
                              color: Color.fromARGB(255, 248, 244, 208),
                              width: 2.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (tailleEcran! >= 6) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets(
                              idTicket: idTicket,
                              idUtilisateur: idUtilisateur,
                              nom: nom,
                              contact: contact,
                              date: date,
                              heure: heure,
                              depart: depart,
                              destination: destination,
                              place: numeroDePlace,
                              etatScann: etatScann,
                              statut: statut,
                              prixTicket: prixTicket,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets2(
                              idTicket: idTicket,
                              idUtilisateur: idUtilisateur,
                              nom: nom,
                              contact: contact,
                              date: date,
                              heure: heure,
                              depart: depart,
                              destination: destination,
                              place: numeroDePlace,
                              etatScann: etatScann,
                              statut: statut,
                              prixTicket: prixTicket,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      " Détails du ticket ",
                      style: TextStyle(
                        color: Color.fromARGB(255, 248, 244, 208),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRight() {
    return Center(
        child: Text(
      "MVST",
      style: TextStyle(
        color: Config.colors.bleuFonce,
        fontFamily: 'Lobster',
        shadows: const [
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(1, 1),
            blurRadius: 1,
          ),
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(-1, -1),
            blurRadius: 1,
          ),
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(1, -1),
            blurRadius: 1,
          ),
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(-1, 1),
            blurRadius: 1,
          ),
        ],
      ),
    ));
  }
}

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
}
