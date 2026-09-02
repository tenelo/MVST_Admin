import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/services/api_client.dart';

class Suppression extends StatefulWidget {
  const Suppression({
    super.key,
    required this.dateHier,
    required this.aujoudhui,
    required this.demain,
    required this.apresDemain,
  });
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

  @override
  void dispose() {
    _rechercheParDate.dispose();
    _rechercheParDestination.dispose();
    _rechercheParNom.dispose();
    _rechercheParHeure.dispose();
    super.dispose();
  }

  Future<void> _getDonnees() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        'suppressionTickets.php',
        body: {
          'dates': [
            widget.dateHier,
            widget.aujoudhui,
            widget.demain,
            widget.apresDemain,
          ],
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tickets = List<Map<String, dynamic>>.from(data['tickets']);
          if (mounted) {
            setState(() {
              donnees = tickets;
              _filtre = tickets;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrerDonnees() {
    final searchDate = _rechercheParDate.text.toLowerCase();
    final searchDestination = _rechercheParDestination.text.toLowerCase();
    final searchNom = _rechercheParNom.text.toLowerCase();
    final searchHeure = _rechercheParHeure.text.toLowerCase();

    setState(() {
      donnees = _filtre.where((data) {
        return data['date'].toString().toLowerCase().contains(searchDate) &&
            data['destination']
                .toString()
                .toLowerCase()
                .contains(searchDestination) &&
            data['nom'].toString().toLowerCase().contains(searchNom) &&
            data['heure'].toString().toLowerCase().contains(searchHeure);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
        title: Text(
          "Maintenir pour supprimer",
          style: TextStyle(
              fontSize: 14,
              color: Config.colors.authCardBackground,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Config.colors.authCardBackground),
            onPressed: _getDonnees,
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(4.0),
        decoration: const BoxDecoration(
          color: Color.fromARGB(143, 228, 227, 227),
        ),
        child: Column(
          children: [
            // ── Champs de recherche ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rechercheParDate,
                      decoration: const InputDecoration(
                        hintText: 'Date',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _rechercheParDestination,
                      decoration: const InputDecoration(
                        hintText: 'Destination',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _rechercheParNom,
                      decoration: const InputDecoration(
                        hintText: 'Nom',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _rechercheParHeure,
                      decoration: const InputDecoration(
                        hintText: 'Heure',
                        hintStyle: TextStyle(fontSize: 11),
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (value) => _filtrerDonnees(),
                    ),
                  ),
                ],
              ),
            ),
            // ── Tableau ───────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: Config.colors.authCardBackground))
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
                                    color: Config.colors.authCardBackground,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                            horizontalMargin: 5,
                            columnSpacing: 20,
                            showFirstLastButtons: true,
                            columns: const [
                              DataColumn(
                                  label: Text('Dates',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Heures',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Départs',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Destinations',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Places',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Tarifs',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Clients',
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 9, 15, 123),
                                          fontWeight: FontWeight.bold))),
                            ],
                            rowsPerPage: _rowsPerPage,
                            availableRowsPerPage: const [10, 20, 50],
                            onRowsPerPageChanged: (int? value) {
                              if (value != null)
                                setState(() => _rowsPerPage = value);
                            },
                            source:
                                TicketDataSource(donnees, context, _getDonnees),
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
  final List<Map<String, dynamic>> tickets;
  final BuildContext context;
  final VoidCallback onRefresh;

  TicketDataSource(this.tickets, this.context, this.onRefresh);

  DateTime parseDate(String dateStr) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').parse(dateStr);
  }

  @override
  DataRow? getRow(int index) {
    if (index >= tickets.length) return null;
    final ticket = tickets[index];
    final date = parseDate(ticket['date'].toString());
    final formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(formattedDate, style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
        DataCell(
            Text(formatHeure(ticket['heure']?.toString() ?? ''), style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
        DataCell(
            Text(ticket['depart'].toString(),
                style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
        DataCell(
            Text(ticket['destination'].toString(),
                style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
        DataCell(
            Text(ticket['place'].toString(),
                style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
        DataCell(
            Text(ticket['prixDuTicket'].toString(),
                style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
        DataCell(
            Text(ticket['nom'].toString(),
                style: const TextStyle(fontSize: 13)),
            onLongPress: () => _supprimerTicket(
                ticket['id'], ticket['idUtilisateur'], ticket['nom'])),
      ],
    );
  }

  void _supprimerTicket(int id, String idUtilisateur, String nom) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titleTextStyle:
              TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold),
          title: const Center(child: Text('Confirmer la suppression')),
          content: RichText(
            text: TextSpan(
              text: 'Êtes-vous sûr de vouloir supprimer le ticket pris par ',
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                    text: nom,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: ' ?'),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Non',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      // ── Supprimer via PHP ──────────────────────────────
                      await ApiClient.instance.post(
                        'suppressionTickets.php',
                        body: {'action': 'supprimer', 'id': id},
                      );

                      // ── Décrémenter points ────────────────────
                      await _decrementerPoints(idUtilisateur);

                      // ── Rafraîchir la liste ────────────────────
                      onRefresh();
                      _afficherMessageConfirmation();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Erreur lors de la suppression.')),
                      );
                    }
                  },
                  child: Text('Oui',
                      style: TextStyle(
                          color: Colors.red[300], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _decrementerPoints(String idUtilisateur) async {
    try {
      await ApiClient.instance.post(
        'decrementerPoints.php',
        body: {'idUtilisateur': idUtilisateur},
      );
    } catch (e) {}
  }

  void _afficherMessageConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Center(child: Text('Ticket supprimé')),
        );
      },
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    });
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tickets.length;

  @override
  int get selectedRowCount => 0;
}
