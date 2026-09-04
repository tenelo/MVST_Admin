import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/graphiques/graiqueMoisAnnee.dart';
import 'package:mvst_admin/graphiques/graphiqueAnnee.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphiquesABarres extends StatefulWidget {
  const GraphiquesABarres({
    super.key,
    required this.gare,
    required this.uid,
    required this.date,
    required this.moisAnnee,
    required this.annee,
  });
  final String gare;
  final String uid;
  final String date;
  final String moisAnnee;
  final String annee;

  @override
  State<GraphiquesABarres> createState() => _GraphiquesABarresState();
}

class _GraphiquesABarresState extends State<GraphiquesABarres> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _monthYearController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  // Controleurs d'AFFICHAGE uniquement (espaces au lieu d'underscores).
  // _dateController/_monthYearController/_yearController restent la valeur
  // TECHNIQUE (underscores), inchangee, utilisee pour la navigation vers
  // l'ecran suivant (date:/moisAnnee:/annee: ci-dessous) et donc au final
  // pour l'appel serveur de cet ecran-la.
  final TextEditingController _dateAffichage = TextEditingController();
  final TextEditingController _moisAnneeAffichage = TextEditingController();
  final TextEditingController _anneeAffichage = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonthYear = DateTime.now();
  DateTime _selectedYear = DateTime.now();
  final List<MesDonneesTickets> ticketsData = [];
  bool _isLoading = true;

  // AFFICHAGE UNIQUEMENT : underscores -> espaces. La valeur technique
  // (underscores) n'est jamais modifiee par cette fonction.
  String _lisible(String valeurTechnique) =>
      valeurTechnique.replaceAll('_', ' ');

  @override
  void initState() {
    super.initState();
    _dateController.text = widget.date;
    _monthYearController.text = widget.moisAnnee;
    _yearController.text = widget.annee;
    _dateAffichage.text = _lisible(widget.date);
    _moisAnneeAffichage.text = _lisible(widget.moisAnnee);
    _anneeAffichage.text = _lisible(widget.annee);
    _chargerTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _monthYearController.dispose();
    _yearController.dispose();
    _dateAffichage.dispose();
    _moisAnneeAffichage.dispose();
    _anneeAffichage.dispose();
    super.dispose();
  }

  // ── Charger les tickets via PHP ────────────────────────────────────────────
  Future<void> _chargerTickets() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.post(
        'graphiques.php',
        body: {
          'type': 'jour',
          'date': widget.date,
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
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                  filteredTickets.isEmpty
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucune donnée pour cette date',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                          labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                      primaryYAxis: const NumericAxis(
                          majorGridLines: MajorGridLines(
                              width: 0.5, color: Color(0xFFE0E0E0)),
                          labelStyle: TextStyle(fontSize: 10),
                          title: AxisTitle(text: 'Passagers')),
                      title: ChartTitle(
                          text:
                              'Nombre de passagers par destinations\npartants de ${widget.gare}',
                          textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Config.colors.bleuA)),
                      // Legende desactivee : une seule serie multicolore
                      // (couleurs posees par pointColorMapper, pas par la
                      // serie) -> une legende classique afficherait une
                      // pastille ne correspondant a aucune barre. Le titre
                      // porte deja le total.
                      legend: const Legend(isVisible: false),
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
                              textStyle:
                                  TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  _buildDatePickers(context),
                ],
              ),
            ),
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateField('Choisissez une date:', _dateAffichage,
              () => _selectDate(context)),
          _buildDateField('Choisissez mois et année:', _moisAnneeAffichage,
              () => _selectMoisEtAnnee(context)),
          _buildDateField('Choisissez l\'année:', _anneeAffichage,
              () => _selectAnnee(context)),
        ],
      ),
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.grey),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                suffixIcon:
                    Icon(Icons.calendar_month_sharp, color: Colors.grey),
              ),
              readOnly: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2024),
        lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(picked);
        _monthYearController.text =
            DateFormat('MMMM_y', 'fr_FR').format(picked);
        _yearController.text = DateFormat('y', 'fr_FR').format(picked);
        _dateAffichage.text = _lisible(_dateController.text);
        _moisAnneeAffichage.text = _lisible(_monthYearController.text);
        _anneeAffichage.text = _lisible(_yearController.text);
      });
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GraphiquesABarres(
                date: _dateController.text,
                moisAnnee: _monthYearController.text,
                annee: _yearController.text,
                gare: widget.gare,
                uid: widget.uid),
          ));
    }
  }

  Future<void> _selectMoisEtAnnee(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedMonthYear,
        firstDate: DateTime(_selectedMonthYear.year - 2, 1),
        lastDate: DateTime(_selectedMonthYear.year, 12),
        initialDatePickerMode: DatePickerMode.year);
    if (picked != null) {
      setState(() {
        _selectedMonthYear = DateTime(picked.year, picked.month);
        _dateController.text =
            DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(_selectedMonthYear);
        _monthYearController.text =
            DateFormat('MMMM_y', 'fr_FR').format(_selectedMonthYear);
        _yearController.text =
            DateFormat('y', 'fr_FR').format(_selectedMonthYear);
        _dateAffichage.text = _lisible(_dateController.text);
        _moisAnneeAffichage.text = _lisible(_monthYearController.text);
        _anneeAffichage.text = _lisible(_yearController.text);
      });
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GraphiquesABarresMoisAnnee(
                date: _dateController.text,
                moisAnnee: _monthYearController.text,
                annee: _yearController.text,
                gare: widget.gare,
                uid: widget.uid),
          ));
    }
  }

  Future<void> _selectAnnee(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedYear,
        firstDate: DateTime(_selectedYear.year - 2),
        lastDate: DateTime(_selectedYear.year, 12),
        initialDatePickerMode: DatePickerMode.year);
    if (picked != null) {
      setState(() {
        _selectedYear = DateTime(picked.year);
        _dateController.text =
            DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(_selectedYear);
        _monthYearController.text =
            DateFormat('MMMM_y', 'fr_FR').format(_selectedYear);
        _yearController.text = DateFormat('y', 'fr_FR').format(_selectedYear);
        _dateAffichage.text = _lisible(_dateController.text);
        _moisAnneeAffichage.text = _lisible(_monthYearController.text);
        _anneeAffichage.text = _lisible(_yearController.text);
      });
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GraphiquesABarresAnnee(
                date: _dateController.text,
                moisAnnee: _monthYearController.text,
                annee: _yearController.text,
                gare: widget.gare,
                uid: widget.uid),
          ));
    }
  }
}

class MesDonneesTickets {
  MesDonneesTickets(this.destinations, this.nombrePassagers);
  final String destinations;
  final int nombrePassagers;
}
