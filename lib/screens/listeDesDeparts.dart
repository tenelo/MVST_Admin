import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/graphiques/graphiqueJourDepart/graphiqueJourDepart.dart';
import 'package:mvst_admin/screens/placesAssisesPE.dart';
import 'package:mvst_admin/screens/ticketsDuJour.dart';

List<Map<String, dynamic>> heuresDepartEtNombreTickets = [];
List<String> listeDesHeures = [];

class ListeTicketsScannes extends StatefulWidget {
  const ListeTicketsScannes(
      {super.key,
      required this.date,
      required this.dateNormale,
      required this.tailleEcran});
  final String date;
  final String dateNormale;
  final int tailleEcran;

  @override
  State<ListeTicketsScannes> createState() => _ListeTicketsScannesState();
}

class _ListeTicketsScannesState extends State<ListeTicketsScannes> {
  Stream<List<Map<String, dynamic>>> recupererLesTicketsScannes() async* {
    final conn = await Connexion.connexionDB();
    try {
      // Requête pour récupérer les heures, le nombre de tickets scannés (par heure), et les champs supplémentaires
      var result = await conn.query(
          'SELECT heureDeDepart,documentId, dateDeDepart,depart,destination,JSON_LENGTH(placesChoisies) as nombreDePlacesChoisies '
          'FROM Departs '
          'WHERE dateDeDepart = ? '
          'GROUP BY documentId',
          [widget.date]);

      // Extraire le résultat des requêtes
      var heuresDepartEtNombreTickets = result
          .map((row) => {
                'heure': row[0].toString(),
                'documentId': row[1],
                'dateDeDepart': row[2].toString(),
                'depart': row[3],
                'destination': row[4],
                'nombreDePlacesChoisies': row[5],
              })
          .toList();
      // Obtenir les heures uniques et formater
      listeDesHeures = heuresDepartEtNombreTickets
          .map((item) => item['heure'].toString() + ' h')
          .toSet()
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
          'Départs',
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
              child: Text(
                'Aucun ticket scanné',
                style: TextStyle(
                    color: Config.colors.bleuFonce2,
                    fontWeight: FontWeight.bold),
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
                      SizedBox(height: 4),
                      Text(
                        "Heures de départs: ${listeDesHeures.join(', ')}",
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
                  padding:
                      EdgeInsets.only(left: 4, top: 2, right: 2, bottom: 4),
                  itemCount: heuresEtTickets.length,
                  itemBuilder: (context, index) {
                    return (widget.tailleEcran <= 6)
                        ? CartePetitEcran(
                            context,
                            heuresEtTickets[index]['heure'],
                            heuresEtTickets[index]['nombreDePlacesChoisies'],
                            heuresEtTickets[index]['documentId'],
                            heuresEtTickets[index]['depart'],
                            heuresEtTickets[index]['destination'],
                            heuresEtTickets[index]['dateDeDepart'],
                            widget.dateNormale,
                          )
                        : CarteGrandEcran(
                            context,
                            heuresEtTickets[index]['heure'],
                            heuresEtTickets[index]['nombreDePlacesChoisies'],
                            heuresEtTickets[index]['documentId'],
                            heuresEtTickets[index]['depart'],
                            heuresEtTickets[index]['destination'],
                            heuresEtTickets[index]['dateDeDepart'],
                            widget.dateNormale,
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

Widget CartePetitEcran(
    BuildContext context,
    String heures,
    int nombrePlacesChoisies,
    String documentId,
    String depart,
    String destination,
    String idDate,
    String date) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 5,
    margin: EdgeInsets.symmetric(vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 68, 190, 255),
            Color.fromARGB(108, 5, 82, 121),
            const Color.fromARGB(255, 53, 96, 237)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Départ de : $heures h",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Nombre de passagers : ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: "$nombrePlacesChoisies",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => GraphiqueJourDepart(
                        documentId: "$documentId",
                        date: date,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Les destinations",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Icon(Icons.bar_chart_sharp, color: Colors.orange)
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => TicketsDuJour(
                        date: date,
                        idDoc: documentId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Les tickets",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Icon(Icons.receipt_outlined, color: Colors.orange)
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => PlacesAssises(
                        documentId: documentId,
                        depart: depart,
                        destination: destination,
                        heure: heures,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Les Places",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Icon(Icons.event_seat, color: Colors.orange)
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

Widget CarteGrandEcran(
    BuildContext context,
    String heures,
    int nombrePlacesChoisies,
    String documentId,
    String depart,
    String destination,
    String idDate,
    String date) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 5,
    margin: EdgeInsets.symmetric(vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 68, 190, 255),
            Color.fromARGB(108, 5, 82, 121),
            const Color.fromARGB(255, 53, 96, 237)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Départ de : $heures h",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Nombre de passagers : ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: "$nombrePlacesChoisies",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => GraphiqueJourDepart(
                        documentId: "$documentId",
                        date: date,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "Les destinations",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Icon(Icons.bar_chart_sharp, color: Colors.orange)
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => PlacesAssises(
                        documentId: documentId,
                        depart: depart,
                        destination: destination,
                        heure: heures,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Places occupées",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Icon(Icons.event_seat, color: Colors.orange)
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => TicketsDuJour(
                        date: date,
                        idDoc: documentId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "Les tickets",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Icon(Icons.receipt_outlined, color: Colors.orange)
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
