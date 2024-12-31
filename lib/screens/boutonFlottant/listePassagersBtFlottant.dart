import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/ticketsDuJour.dart';

List<Map<String, dynamic>> heuresDepartEtNombreTickets = [];
List<String> listeDesHeures = [];
String? heuresFormattees;

class DepartsListePassagersPourBtFlottant extends StatefulWidget {
  const DepartsListePassagersPourBtFlottant(
      {super.key,
      required this.date,
      required this.dateNormale,
      required this.tailleEcran});
  final String date;
  final String dateNormale;
  final int tailleEcran;

  @override
  State<DepartsListePassagersPourBtFlottant> createState() =>
      _DepartsListePassagersPourBtFlottantState();
}

class _DepartsListePassagersPourBtFlottantState
    extends State<DepartsListePassagersPourBtFlottant> {
  Stream<List<Map<String, dynamic>>> recupererLesTicketsScannes() async* {
    final conn = await Connexion.connexionDB();
    try {
      // Requête pour récupérer les heures, le nombre de tickets scannés (par heure), et les champs supplémentaires
      var result = await conn.query(
          'SELECT heureDeDepart,documentId, dateDeDepart,depart,destination,JSON_LENGTH(placesChoisies) as nombreDePlacesChoisies '
          'FROM Departs '
          'WHERE dateDeDepart = ? '
          'GROUP BY documentId ',
          [widget.date]);

      // Extraire le résultat des requêtes
      var heuresDepartEtNombreTickets = result
          .map((row) => {
                'heure': row[0].toString(),
                'documentId': row[1],
              })
          .toList();

      yield heuresDepartEtNombreTickets;
    } catch (e) {
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        title: Text(
          'Passagers',
          style: TextStyle(
              color: Config.colors.bleuFonce2, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: recupererLesTicketsScannes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

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

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  'Aucun ticket pris pour le départ du ${widget.dateNormale}',
                  style: TextStyle(
                      color: Config.colors.bleuFonce2,
                      fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          final heuresEtTickets = snapshot.data!;

          return Column(
            children: [
              // Zone fixe au dessus de la liste
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.blueGrey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Le ${widget.dateNormale} ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Nombre de départs: ${heuresEtTickets.length}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: heuresEtTickets.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
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
                                builder: (context) => TicketsDuJour(
                                  date: widget.date,
                                  idDoc: heuresEtTickets[index]['documentId'],
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "Départ de ${heuresEtTickets[index]['heure']} h",
                            style: TextStyle(
                              fontSize: 16,
                              color: Config.colors.bleuClaire,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
