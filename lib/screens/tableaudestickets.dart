import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:mysql1/mysql1.dart';

class TableauDeTickets extends StatefulWidget {
  const TableauDeTickets({Key? key, required this.date}) : super(key: key);
  final String date;
  @override
  State<TableauDeTickets> createState() => _TableauDeTicketsState();
}

class _TableauDeTicketsState extends State<TableauDeTickets> {
  int _rowsPerPage = 20;
  bool _isLoading = true;
  List<Map<String, dynamic>> donnees = [];
  List<Map<String, dynamic>> _filtre = [];
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();
  final TextEditingController _rechercheParNom = TextEditingController();

  MySqlConnection? _connection;

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
      // Connexion à la base de données MySQL
      _connection = await Connexion.connexionDB();
      String sql = '''
      SELECT t.*
      FROM Tickets t
      JOIN (
        SELECT d.documentId
        FROM Departs d
        WHERE d.annee = ?
      ) AS selectedDeparts
      ON t.documentId = selectedDeparts.documentId
      ORDER BY dateDeCreation DESC;
    ''';

      // Exécuter la requête en utilisant l'année passée via `widget.date`
      Results result = await _connection!.query(sql, [widget.date]);

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
    String searchDate = _rechercheParDate.text.toLowerCase();
    String searchDestination = _rechercheParDestination.text.toLowerCase();
    String searchNom = _rechercheParNom.text.toLowerCase();

    setState(() {
      donnees = _filtre.where((data) {
        final dataDate = data['date'].toString().toLowerCase();
        final dataDestination = data['destination'].toString().toLowerCase();
        final dataNom = data['nom'].toString().toLowerCase();
        return dataDate.contains(searchDate) &&
            dataDestination.contains(searchDestination) &&
            dataNom.contains(searchNom);
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
          "Tous les tickets",
          style: TextStyle(
              color: Config.colors.bleuFonce2, fontWeight: FontWeight.bold),
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
                    width: 200,
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
    var idDuTicket = ticket['documentId'];
    DateTime date = parseDate(ticket['date'].toString());

    String formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(formattedDate, style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text("${ticket['heure']} h", style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text(ticket['depart'], style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text(ticket['destination'], style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(
            Text(ticket['place'].toString(), style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(
            Text(ticket['prixDuTicket'].toString(),
                style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text(ticket['nom'].toString(), style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
      ],
    );
  }

  void _onTapRow(Map<String, dynamic> ticket, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsTickets(
          idTicket: id,
          idUtilisateur: ticket['idUtilisateur'],
          nom: ticket['nom'],
          contact: ticket['telephone'],
          date: ticket['date'],
          heure: ticket['heure'],
          depart: ticket['depart'],
          destination: ticket['destination'],
          place: ticket['place'],
          etatScann: ticket['etatScanne'],
          statut: ticket['statut'],
          prixTicket: ticket['prixDuTicket'].toString(),
          datePourCalcule: ticket['datePourCalcule'],
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tickets.length;

  @override
  int get selectedRowCount => 0;
}
