import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphiqueJourDepart extends StatefulWidget {
  const GraphiqueJourDepart({
    super.key,
    required this.gare,
    required this.destination,
    required this.uid,
    required this.documentId,
    required this.date,
  });
  final String gare;
  final String destination;
  final String uid;
  final String documentId;
  final String date;

  @override
  State<GraphiqueJourDepart> createState() => _GraphiqueJourDepartState();
}

class _GraphiqueJourDepartState extends State<GraphiqueJourDepart> {
  final TextEditingController _searchController = TextEditingController();
  final List<MesDonneesTickets> ticketsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Charger les tickets via PHP ────────────────────────────────────────────
  Future<void> _chargerTickets() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        'ticketsDuJour.php',
        body: {
          'documentId': widget.documentId,
          'gare': widget.gare,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _classerLesTickets(List<Map<String, dynamic>>.from(data['tickets']));
        }
      }
    } catch (e) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _classerLesTickets(List<Map<String, dynamic>> tickets) {
    final Map<String, int> destinationCounts = {};
    for (var ticket in tickets) {
      final destination = ticket['destination'] ?? '';
      destinationCounts[destination] =
          (destinationCounts[destination] ?? 0) + 1;
    }
    ticketsData.clear();
    destinationCounts.forEach((destination, count) {
      ticketsData.add(MesDonneesTickets(destination, count));
    });
  }

  List<MesDonneesTickets> _getFilteredTickets() {
    final query = _searchController.text.toLowerCase();
    return ticketsData
        .where((t) => t.destinations.toLowerCase().contains(query))
        .toList();
  }

  int _getTotalPassagers() =>
      ticketsData.fold(0, (sum, t) => sum + t.nombrePassagers);

  

  final List<Color> listeDesCouleurs = const [
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
    Color.fromARGB(255, 78, 52, 46),
    Color.fromARGB(255, 0, 131, 143),
    Color.fromARGB(255, 242, 121, 53),
    Color.fromARGB(255, 111, 194, 169),
    Color.fromARGB(255, 173, 94, 154),
    Color.fromARGB(255, 255, 236, 79),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTickets = _getFilteredTickets();
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
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
              borderSide: const BorderSide(
                color: Colors.blueAccent,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: const BorderSide(color: Colors.blue, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      primaryYAxis: const NumericAxis(
                        majorGridLines: MajorGridLines(width: 0),
                        labelStyle: TextStyle(fontSize: 0),
                      ),
                      title: ChartTitle(
                        text:
                            '${widget.gare} -> ${widget.destination} ${widget.date}',
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Config.colors.bleuA,
                        ),
                      ),
                      legend: const Legend(
                        isVisible: true,
                        textStyle: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries<MesDonneesTickets, String>>[
                        BarSeries<MesDonneesTickets, String>(
                          borderRadius: BorderRadius.circular(4),
                          sortingOrder: SortingOrder.descending,
                          name:
                              'Passagers du ${widget.date} : ${_getTotalPassagers()}',
                          dataSource: filteredTickets,
                          xValueMapper: (d, _) => d.destinations,
                          yValueMapper: (d, _) => d.nombrePassagers,
                          pointColorMapper: (d, i) =>
                              listeDesCouleurs[i % listeDesCouleurs.length],
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MesDonneesTickets {
  MesDonneesTickets(this.destinations, this.nombrePassagers);
  final String destinations;
  final int nombrePassagers;
}
