import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mysql1/mysql1.dart';

MySqlConnection? _connection;

class Suppression extends StatefulWidget {
  const Suppression(
      {super.key,
      required this.dateHier,
      required this.aujoudhui,
      required this.demain,
      required this.apresDemain});
  final String dateHier;
  final String aujoudhui;
  final String demain;
  final String apresDemain;
  @override
  State<Suppression> createState() => _SuppressionState();
}

class _SuppressionState extends State<Suppression> {
  int _rowsPerPage = 20;
  bool _isLoading = true;
  List<Map<String, dynamic>> donnees = [];
  List<Map<String, dynamic>> _filtre = [];
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();
  final TextEditingController _rechercheParNom = TextEditingController();
  final TextEditingController _rechercheParHeure = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getDonnees();
  }

  void _getDonnees() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _connection = await Connexion.connexionDB();

      var result = await _connection!.query(
        'SELECT * FROM Tickets WHERE date IN (?, ?, ?, ?) ORDER BY dateDeCreation DESC',
        [widget.dateHier, widget.aujoudhui, widget.demain, widget.apresDemain],
      );

      // Transformation du résultat en liste de maps
      List<Map<String, dynamic>> tickets =
          result.map((row) => row.fields).toList();

      setState(() {
        donnees = tickets;
        _filtre = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filtrerDonnees() {
    String rechercheDate = _rechercheParDate.text.toLowerCase();
    String rechercheDestination = _rechercheParDestination.text.toLowerCase();
    String rechercheNom = _rechercheParNom.text.toLowerCase();
    String rechercheHeure = _rechercheParHeure.text.toLowerCase();

    setState(() {
      donnees = _filtre.where((data) {
        final dataDate = data['date'].toString().toLowerCase();
        final dataDestination = data['destination'].toString().toLowerCase();
        final dataNom = data['nom'].toString().toLowerCase();
        final dataHeure = data['heure'].toString().toLowerCase();
        return dataDate.contains(rechercheDate) &&
            dataDestination.contains(rechercheDestination) &&
            dataNom.contains(rechercheNom) &&
            dataHeure.contains(rechercheHeure);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        title: Text(
          "Maintenir pour supprimer",
          style: TextStyle(
              fontSize: 14,
              color: Config.colors.bleuFonce2,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height * 1,
        padding: const EdgeInsets.all(4.0),
        decoration: const BoxDecoration(
          color: Color.fromARGB(143, 228, 227, 227),
        ),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 170,
                    height: 40,
                    child: TextField(
                      controller: _rechercheParDate,
                      decoration: const InputDecoration(
                        hintText: 'Recherche par date',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                  SizedBox(
                    width: 198,
                    height: 40,
                    child: TextField(
                      controller: _rechercheParDestination,
                      decoration: const InputDecoration(
                        hintText: 'Recherche par destination',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    height: 40,
                    child: TextField(
                      controller: _rechercheParNom,
                      decoration: const InputDecoration(
                        hintText: 'Recherche par nom',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    height: 40,
                    child: TextField(
                      controller: _rechercheParHeure,
                      decoration: const InputDecoration(
                        hintText: 'Recherche par heure',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Theme(
                          data: ThemeData.light().copyWith(
                              cardColor: Theme.of(context).canvasColor),
                          child: PaginatedDataTable(
                            header: Center(
                              child: Text(
                                "NOMBRE TOTAL DE TICKETS : ${donnees.length}",
                                style: TextStyle(
                                    color: Config.colors.bleuFonce2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                            horizontalMargin: 5,
                            columnSpacing: 20,
                            showFirstLastButtons: true,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Dates',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Heures',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Départs',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Destinations',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Places',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Tarifs',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Clients',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rowsPerPage: _rowsPerPage,
                            availableRowsPerPage: const [10, 20, 50],
                            onRowsPerPageChanged: (int? value) {
                              if (value != null) {
                                setState(() {
                                  _rowsPerPage = value;
                                });
                              }
                            },
                            source: TicketDataSource(donnees, context),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketDataSource extends DataTableSource {
  List<Map<String, dynamic>> tickets;
  final BuildContext context;

  TicketDataSource(this.tickets, this.context);

  DateTime parseDate(String dateStr) {
    DateFormat dateFormatFr = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    DateTime dateTime = dateFormatFr.parse(dateStr);
    return dateTime;
  }

  @override
  DataRow? getRow(int index) {
    if (index >= tickets.length) return null;
    final ticketSnapshot = tickets[index];
    final ticket = ticketSnapshot;
    var idDuTicket = ticket['id'];
    var idUtilisateur = ticket['idUtilisateur'];
    DateTime date = parseDate(ticket['date'].toString());

    String formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(formattedDate, style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
        DataCell(Text("${ticket['heure']} h", style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
        DataCell(Text(ticket['depart'], style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
        DataCell(Text(ticket['destination'], style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
        DataCell(
            Text(ticket['place'].toString(), style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
        DataCell(
            Text(ticket['prixDuTicket'].toString(),
                style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
        DataCell(Text(ticket['nom'].toString(), style: TextStyle(fontSize: 13)),
            onLongPress: () =>
                supprimerTicket(idDuTicket, idUtilisateur, ticket['nom'])),
      ],
    );
  }

  void supprimerTicket(int id, String idUtilisateur, String nom) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titleTextStyle: TextStyle(
            color: Colors.red[300],
            fontWeight: FontWeight.bold,
          ),
          title: Center(child: Text('Confirmer la suppression')),
          content: RichText(
            text: TextSpan(
              text: 'Êtes-vous sûr de vouloir supprimer le ticket pris par ',
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold), // Gras pour le nom
                ),
                const TextSpan(
                  text: ' ?',
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Non',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      _connection = await Connexion.connexionDB();
                      await _connection!
                          .query('DELETE FROM Tickets WHERE id = ?', [id]);

                      decrementerPointsFirebase(idUtilisateur);
                      decrementePointsMySQL(idUtilisateur);
                      afficherMessageConfirmation();
                    } catch (e) {
                      // Afficher un message d'erreur en cas d'échec
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la suppression.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Oui',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> decrementerPointsFirebase(String idDoc) async {
    try {
      // Référence au document de l'utilisateur
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('utilisateurs').doc(idDoc);

      // Transaction pour récupérer et mettre à jour le nombre de points
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Récupérer le document actuel
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (snapshot.exists) {
          // Obtenir le nombre de points actuel
          int points = snapshot['points'] ?? 0;

          // Réduire de 1 le nombre de points, en s'assurant qu'il ne devienne pas négatif
          int nouveauxPoints = (points > 0) ? points - 1 : 0;

          // Mettre à jour les points dans Firestore
          transaction.update(userRef, {'points': nouveauxPoints});
        } else {
          throw Exception("Utilisateur non trouvé");
        }
      });
    } catch (e) {}
  }

  Future<void> decrementePointsMySQL(String idUtilisateur) async {
    try {
      _connection = await Connexion.connexionDB();
      var result = await _connection!.query(
        'UPDATE Utilisateurs SET points = points - 1 WHERE idUtilisateur = ?',
        [idUtilisateur],
      );
      // Vérifier si la requête a été exécutée avec succès
      if (result.affectedRows! > 0) {
      } else {}
    } catch (e) {}
  }

  void afficherMessageConfirmation() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Ticket supprimé')),
        );
      },
    );

    // Fermer l'AlertDialog après 2 secondes
    Future.delayed(Duration(seconds: 5), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Fermer l'AlertDialog automatiquement
      }
    });
    Navigator.of(context).pop();
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tickets.length;

  @override
  int get selectedRowCount => 0;
}
