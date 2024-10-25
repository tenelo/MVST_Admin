import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mysql1/mysql1.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphiqueJourDepart extends StatefulWidget {
  const GraphiqueJourDepart(
      {super.key, required this.documentId, required this.date});
  final String documentId;
  final String date;
  @override
  State<GraphiqueJourDepart> createState() => _GraphiqueJourDepartState();
}

class _GraphiqueJourDepartState extends State<GraphiqueJourDepart> {
  final TextEditingController _searchController = TextEditingController();
  MySqlConnection? _connection;
  final List<MesDonneesTickets> ticketsData = [];

  @override
  void initState() {
    super.initState();
    recuperationDesTickets();
  }

  List<Color> listeDesCouleurs = [
    Color.fromARGB(192, 6, 90, 132),
    Color.fromARGB(255, 255, 192, 0),
    Color.fromARGB(225, 85, 144, 80),
    Color.fromARGB(255, 144, 173, 255),
    Color.fromARGB(255, 192, 0, 0),
    Color.fromARGB(255, 0, 205, 153),
    Color.fromARGB(255, 129, 56, 247),
    Color.fromARGB(255, 204, 236, 255),
    Color.fromARGB(255, 241, 167, 138),
    Color.fromARGB(213, 57, 103, 255),
    Color.fromARGB(255, 236, 141, 255),
    Color.fromARGB(255, 244, 80, 68),
  ];

  Stream<List<Map<String, dynamic>>> recuperationDesTickets() async* {
    // Connexion à la base de données MySQL
    _connection = await Connexion.connexionDB();
    String sql = '''
  SELECT *
  FROM Tickets
  WHERE documentId = ?
''';
    try {
      Results result = await _connection!.query(sql, [widget.documentId]);

      // Transformation du résultat en liste de maps
      List<Map<String, dynamic>> tickets =
          result.map((row) => row.fields).toList();

      // Classification des tickets
      _classifyTickets(tickets);

      // Émission des résultats dans le Stream
      yield tickets;
    } catch (e) {
      print('Erreur lors de la récupération des tickets : $e');
      yield [];
    }
  }

  void _classifyTickets(List<Map<String, dynamic>> tickets) {
    Map<String, int> destinationCounts = {};

    for (var ticket in tickets) {
      var destination = ticket['destination'] ?? '';
      destinationCounts[destination] =
          (destinationCounts[destination] ?? 0) + 1;
    }

    ticketsData.clear();
    destinationCounts.forEach((destination, count) {
      ticketsData.add(MesDonneesTickets(destination, count));
    });
  }

  List<MesDonneesTickets> getFilteredTickets() {
    String query = _searchController.text.toLowerCase();
    return ticketsData
        .where((ticket) => ticket.destinations.toLowerCase().contains(query))
        .toList();
  }

  int getTotalPassagers() {
    return ticketsData.fold(0, (sum, ticket) => sum + ticket.nombrePassagers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.bleuFonce2,
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
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
          onChanged: (value) {
            setState(() {}); // Actualiser l'état pour déclencher la recherche
          },
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: recuperationDesTickets(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Problème de connexion',
                style: TextStyle(
                    color: Config.colors.bleuFonce2,
                    fontWeight: FontWeight.bold),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {}

          final filteredTickets = getFilteredTickets();

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(
                          //text: 'Nombre de Passagers',
                          ),
                      majorGridLines: MajorGridLines(width: 0),
                      labelStyle: TextStyle(fontSize: 0),
                    ),
                    title: ChartTitle(
                        text: 'Répartition des Passagers par Destination',
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Config.colors.bleuA)),
                    legend: Legend(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<MesDonneesTickets, String>>[
                      BarSeries<MesDonneesTickets, String>(
                        borderRadius: BorderRadius.circular(4),
                        sortingOrder: SortingOrder.descending,
                        color: Colors.orange,
                        name:
                            'Passagers pour le ${widget.date} : ${getTotalPassagers()}',
                        dataSource: filteredTickets,
                        xValueMapper: (MesDonneesTickets data, _) =>
                            data.destinations,
                        yValueMapper: (MesDonneesTickets data, _) =>
                            data.nombrePassagers,
                        pointColorMapper: (MesDonneesTickets data, int index) =>
                            listeDesCouleurs[index % listeDesCouleurs.length],
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MesDonneesTickets {
  MesDonneesTickets(this.destinations, this.nombrePassagers);
  final String destinations;
  final int nombrePassagers;
}
