import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:mvst_admin/screens/petitsEcrans/detailsTickets2.dart';
import 'package:mysql1/mysql1.dart';
import 'package:ticket_material/ticket_material.dart';

int? tailleEcran;

class MesTicketsScannes extends StatefulWidget {
  const MesTicketsScannes({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  State<MesTicketsScannes> createState() => _MesTicketsScannesState();
}

class _MesTicketsScannesState extends State<MesTicketsScannes> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  MySqlConnection? _connection;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connection?.close();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> recupererLesTicketsScannes() async* {
    _connection = await Connexion.connexionDB();
    try {
      var result = await _connection!.query(
          'SELECT * FROM Tickets WHERE documentId = ? AND etatScanne = ? ',
          [widget.documentId, 'scanné']);
      // Transformation du résultat en liste de maps
      List<Map<String, dynamic>> tickets =
          result.map((row) => row.fields).toList();
      // Émission des résultats dans le Stream
      yield tickets;
    } catch (e) {
      yield [];
    }
  }

  List<Map<String, dynamic>> _filterTickets(
      List<Map<String, dynamic>> tickets) {
    if (_searchText.isEmpty) return tickets;
    return tickets.where((ticket) {
      return ticket['nom'].toString().toLowerCase().contains(_searchText) ||
          ticket['telephone'].toString().toLowerCase().contains(_searchText) ||
          ticket['date'].toString().toLowerCase().contains(_searchText) ||
          ticket['depart'].toString().toLowerCase().contains(_searchText) ||
          ticket['destination'].toString().toLowerCase().contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    tailleEcran = Calcule.tailleEcran(context).round();
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        centerTitle: true,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide(color: Colors.blue, width: 2.0),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: recupererLesTicketsScannes(),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Vérifier la connexion',
                    style: TextStyle(
                        color: Config.colors.bleuFonce2,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "Vous n'avez scanné aucun ticket",
                    style: TextStyle(
                        color: Config.colors.bleuFonce2,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }
              final filteredTickets = _filterTickets(snapshot.data!);

              return ListView.builder(
                itemCount: filteredTickets.length,
                itemBuilder: (BuildContext context, int index) {
                  Map<String, dynamic> ticket = filteredTickets[index];
                  var idTicket = ticket['documentId'];
                  DateTime date = DateTime.parse(ticket['date']);
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
                        DateFormat('EEEE d MMMM y', 'fr_FR').format(date),
                        ticket['heure'],
                        ticket['depart'],
                        ticket['destination'],
                        ticket['place'],
                        ticket['etatScanne'],
                        ticket['prixDuTicket'].toString(),
                        ticket['statut'],
                        ticket['datePourCalcule'],
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
    String statut,
    DateTime dateCalcule,
  ) {
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
                datePourCalcule: dateCalcule,
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
                datePourCalcule: dateCalcule,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, right: 2, bottom: 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Départ du : "),
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Heure de départ : "),
                Text(heure,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Siège : "),
                Text("N° $numeroDePlace",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                    child: const Text(
                      "Voir les détails",
                      style: TextStyle(color: Colors.white),
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
                              datePourCalcule: dateCalcule,
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
                              datePourCalcule: dateCalcule,
                            ),
                          ),
                        );
                      }
                    },
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
    return const Padding(
      padding: EdgeInsets.all(2.0),
      child: RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            "MVST",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
