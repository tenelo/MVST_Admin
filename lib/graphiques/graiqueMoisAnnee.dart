import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/graphiques/diagrammeABarres.dart';
import 'package:mvst_admin/graphiques/graphiqueAnnee.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphiquesABarresMoisAnnee extends StatefulWidget {
  const GraphiquesABarresMoisAnnee({super.key, required this.date});
  final String date;

  @override
  State<GraphiquesABarresMoisAnnee> createState() =>
      _GraphiquesABarresMoisAnneeState();
}

class _GraphiquesABarresMoisAnneeState
    extends State<GraphiquesABarresMoisAnnee> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // Controller pour la date
  final TextEditingController _monthYearController =
      TextEditingController(); // Controller pour mois et année
  final TextEditingController _yearController =
      TextEditingController(); // Controller pour l'année uniquement
  DateTime _selectedDate = DateTime.now(); // Date par défaut
  DateTime _selectedMonthYear = DateTime.now(); // Mois et année par défaut
  DateTime _selectedYear = DateTime.now(); // Année par défaut

  final List<MesDonneesTickets> ticketsData = [];

  @override
  void initState() {
    super.initState();
    recuperationDesTickets();
  }

  List<Color> listeDesCouleurs = [
    Color.fromARGB(192, 6, 90, 132),
    Color.fromARGB(218, 248, 211, 62),
    Color.fromARGB(225, 85, 144, 80),
    Color.fromARGB(255, 144, 173, 255),
    Color.fromARGB(255, 172, 248, 50),
    Color.fromARGB(255, 50, 245, 235),
    Color.fromARGB(255, 129, 56, 247),
    Color.fromARGB(213, 57, 103, 255),
    Color.fromARGB(255, 236, 141, 255),
    Color.fromARGB(255, 244, 80, 68),
  ];

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>>
      recuperationDesTickets() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .where('moisAnnee', isEqualTo: widget.date)
        .snapshots()
        .asyncMap((ticketsSnapshot) async {
      List<DocumentSnapshot<Map<String, dynamic>>> allDocuments = [];
      for (var ticketDoc in ticketsSnapshot.docs) {
        try {
          var subcollectionSnapshot = await ticketDoc.reference
              .collection('sousCollectionTickets')
              .get();
          allDocuments.addAll(subcollectionSnapshot.docs);
        } catch (e) {
          print('Erreur de chargement du ticket ${ticketDoc.id}: $e');
        }
      }

      _classifyTickets(allDocuments);

      return allDocuments;
    });
  }

  void _classifyTickets(List<DocumentSnapshot<Map<String, dynamic>>> tickets) {
    Map<String, int> destinationCounts = {};

    for (var ticket in tickets) {
      var data = ticket.data();
      if (data != null) {
        var destination = data['destination'] ?? '';
        destinationCounts[destination] =
            (destinationCounts[destination] ?? 0) + 1;
      }
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(_selectedDate);
      });
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GraphiquesABarres(
          date: _dateController.text,
        ),
      ),
    );
  }

  Future<void> _selectMoisEtAnnee(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonthYear,
      firstDate: DateTime(_selectedMonthYear.year - 100, 1),
      lastDate: DateTime(_selectedMonthYear.year + 100, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedMonthYear) {
      setState(() {
        _selectedMonthYear = DateTime(picked.year, picked.month);
        _monthYearController.text =
            DateFormat('MMMM_y', 'fr_FR').format(_selectedMonthYear);
      });
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GraphiquesABarresMoisAnnee(
          date: _monthYearController.text,
        ),
      ),
    );
  }

  Future<void> _selectAnnee(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedYear,
      firstDate: DateTime(_selectedYear.year - 100),
      lastDate: DateTime(_selectedYear.year + 100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedYear) {
      setState(() {
        _selectedYear = DateTime(picked.year);
        _yearController.text = DateFormat('y', 'fr_FR').format(_selectedYear);
        GraphiquesABarresAnnee(date: _yearController.text);
      });
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GraphiquesABarresAnnee(
          date: _yearController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
        stream: recuperationDesTickets(),
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
              child: Text(
                "Vous n'avez aucun ticket",
                style: TextStyle(
                    color: Config.colors.bleuFonce2,
                    fontWeight: FontWeight.bold),
              ),
            );
          }

          final filteredTickets = getFilteredTickets();

          return Column(
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
                    title: AxisTitle(text: 'Nombre de Passagers'),
                    majorGridLines: MajorGridLines(width: 0),
                    labelStyle: TextStyle(fontSize: 0),
                  ),
                  title: ChartTitle(
                      text: 'Répartition des Passagers par Destination',
                      textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Config.colors.bleuA)),
                  legend: Legend(isVisible: true),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries<MesDonneesTickets, String>>[
                    BarSeries<MesDonneesTickets, String>(
                      borderRadius: BorderRadius.circular(10),
                      sortingOrder: SortingOrder.descending,
                      color: Colors.orange,
                      name: 'Total Passagers ${getTotalPassagers()}',
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
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choisissez une date:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateController,
                          style: TextStyle(color: Colors.grey),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                            suffixIcon: Icon(
                              Icons.calendar_month_sharp,
                              color: Colors.grey,
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                    ),
                    Text(
                      'Choisissez mois et année:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectMoisEtAnnee(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _monthYearController,
                          style: TextStyle(color: Colors.grey),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                            suffixIcon: Icon(
                              Icons.calendar_month_sharp,
                              color: Colors.grey,
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                    ),
                    Text(
                      'Choisissez l\'année:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectAnnee(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _yearController,
                          style: TextStyle(color: Colors.grey),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                            suffixIcon: Icon(
                              Icons.calendar_month_sharp,
                              color: Colors.grey,
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
