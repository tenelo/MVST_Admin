import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/graphiques/graphiqueJourDepart/graphiqueJourDepart.dart';
import 'package:mvst_admin/screens/listeTicketsScannes.dart';

List<Map<String, dynamic>> heuresDepartEtNombreTickets = [];
List<String> listeDesHeures = [];

class ListeTicketsScannes extends StatefulWidget {
  const ListeTicketsScannes(
      {super.key, required this.date, required this.dateNormale});
  final String date;
  final String dateNormale;

  @override
  State<ListeTicketsScannes> createState() => _ListeTicketsScannesState();
}

class _ListeTicketsScannesState extends State<ListeTicketsScannes> {
  Stream<List<Map<String, dynamic>>> recupererLesTicketsScannes() async* {
    final conn = await Connexion.connexionDB();
    try {
      // Requête pour récupérer les heures, le nombre de tickets scannés (par heure), et les champs supplémentaires
      var result = await conn.query(
          'SELECT heureDeDepart,documentId, dateDeDepart ,JSON_LENGTH(placesChoisies) as nombreDePlacesChoisies '
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
                'nombreDePlacesChoisies': row[3],
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
              // Liste défilante avec ListView.builder
              Expanded(
                child: ListView.builder(
                  padding:
                      EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 16),
                  itemCount: heuresEtTickets.length,
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 8),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Départ de : ${heuresEtTickets[index]['heure']} h",
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
                                    text:
                                        "${heuresEtTickets[index]['nombreDePlacesChoisies']}",
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
                                        builder: (BuildContext context) =>
                                            GraphiqueJourDepart(
                                          documentId:
                                              "${heuresEtTickets[index]['documentId']}",
                                          date: widget.dateNormale,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Les destinations",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 2,
                                      ),
                                      Icon(Icons.bar_chart_sharp,
                                          color: Colors.orange)
                                    ],
                                  ),
                                ),
                                SizedBox(),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            MesTicketsScannes(
                                          documentId:
                                              "${heuresEtTickets[index]['documentId']}",
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.8),
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
                                      Icon(Icons.receipt_outlined,
                                          color: Colors.orange)
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
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
