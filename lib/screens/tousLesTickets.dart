import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:mvst_admin/services/api_client.dart';

class TousLesTickets extends StatefulWidget {
  const TousLesTickets({
    Key? key,
    required this.gare,
    required this.uid,
    required this.date,
  }) : super(key: key);
  final String gare;
  final String uid;
  final String date;

  @override
  State<TousLesTickets> createState() => _TousLesTicketsState();
}

class _TousLesTicketsState extends State<TousLesTickets> {
  int _rowsPerPage = 20;
  bool _isLoading = true;
  late DateTime _dateSelectionnee;
  List<Map<String, dynamic>> donnees = [];
  List<Map<String, dynamic>> _filtre = [];
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();
  final TextEditingController _rechercheParNom = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateSelectionnee = DateTime(
      int.tryParse(widget.date) ?? DateTime.now().year,
    );
    _getDonnees();
  }

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime(2026),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _dateSelectionnee = picked);
      _getDonnees();
    }
  }

  @override
  void dispose() {
    _rechercheParDate.dispose();
    _rechercheParDestination.dispose();
    _rechercheParNom.dispose();
    super.dispose();
  }

  Future<void> _getDonnees() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        'tableauAdmin.php',
        body: {
          'annee': DateFormat('y').format(_dateSelectionnee),
          'gare': widget.gare,
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

    setState(() {
      donnees = _filtre.where((data) {
        return data['date'].toString().toLowerCase().contains(searchDate) &&
            data['destination'].toString().toLowerCase().contains(
              searchDestination,
            ) &&
            data['nom'].toString().toLowerCase().contains(searchNom);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
        title: Text(
          "Tous les tickets",
          style: TextStyle(
            color: Config.colors.authCardBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: Config.colors.authCardBackground,
            ),
            onPressed: _choisirDate,
          ),
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
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                children: [
                  _champRecherche(_rechercheParDate, 'Date', flex: 3),
                  const SizedBox(width: 6),
                  _champRecherche(
                    _rechercheParDestination,
                    'Destination',
                    flex: 5,
                  ),
                  const SizedBox(width: 6),
                  _champRecherche(_rechercheParNom, 'Nom', flex: 3),
                ],
              ),
            ),
            // ── Tableau ───────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Config.colors.authCardBackground,
                      ),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Theme(
                          data: ThemeData.light().copyWith(
                            cardColor: Theme.of(context).canvasColor,
                          ),
                          child: PaginatedDataTable(
                            header: Center(
                              child: Text(
                                "NOMBRE TOTAL DE TICKETS : ${donnees.length}",
                                style: TextStyle(
                                  color: Config.colors.authCardBackground,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Heures',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Départs',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Destinations',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Places',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Tarifs',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Clients',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Type',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rowsPerPage: _rowsPerPage,
                            availableRowsPerPage: const [10, 20, 50],
                            onRowsPerPageChanged: (int? value) {
                              if (value != null)
                                setState(() => _rowsPerPage = value);
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

  Widget _champRecherche(
    TextEditingController controller,
    String hint, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintMaxLines: 1,
          hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
        ),
        onChanged: (value) => _filtrerDonnees(),
      ),
    );
  }
}

class TicketDataSource extends DataTableSource {
  final List<Map<String, dynamic>> tickets;
  final BuildContext context;

  TicketDataSource(this.tickets, this.context);

  DateTime parseDate(String dateStr) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').parse(dateStr);
  }

  @override
  DataRow? getRow(int index) {
    if (index >= tickets.length) return null;
    final ticket = tickets[index];
    final date = parseDate(ticket['date'].toString());
    final formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    final tailleEcran = calculeTailleEcran(context).round();

    final isVip = ticket['typeVoyage']?.toString().toLowerCase() == 'vip';
    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>(
        (states) =>
            isVip ? const Color(0xFFFFD700).withValues(alpha: 0.08) : null,
      ),
      cells: [
        DataCell(
          Text(formattedDate, style: const TextStyle(fontSize: 13)),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          Text(
            formatHeure(ticket['heure']?.toString() ?? ''),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          Text(
            ticket['depart'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          Text(
            ticket['destination'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          Text(
            ticket['place'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          Text(
            ticket['prixDuTicket'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          Text(ticket['nom'].toString(), style: const TextStyle(fontSize: 13)),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
        DataCell(
          _TypeBadge(type: ticket['typeVoyage']?.toString() ?? 'standard'),
          onTap: () => _onTapRow(ticket, tailleEcran),
        ),
      ],
    );
  }

  void _onTapRow(Map<String, dynamic> ticket, int tailleEcran) {
    final datePourCalcule = ticket['datePourCalcule'] != null
        ? DateTime.parse(ticket['datePourCalcule'].toString())
        : DateTime.now();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsTickets(
          idTicket: ticket['documentId'].toString(),
          idUtilisateur: ticket['idUtilisateur'].toString(),
          nom: ticket['nom'].toString(),
          contact: ticket['telephone'].toString(),
          date: ConvertirHeure.formatDate(ticket['date'].toString()),
          heure: ticket['heure'].toString(),
          depart: ticket['depart'].toString(),
          destination: ticket['destination'].toString(),
          place: ticket['place'],
          etatScann: ticket['etatScanne'].toString(),
          statut: ticket['statut'].toString(),
          prixTicket: ticket['prixDuTicket'].toString(),
          datePourCalcule: datePourCalcule,
          typeVoyage: ticket['typeVoyage']?.toString() ?? 'standard',
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

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
}

// ── Badge VIP / Standard ──────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final bool isVip = type.toLowerCase() == 'vip';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVip
            ? const Color(0xFFFFD700).withValues(alpha: 0.15)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVip ? const Color(0xFFB8860B) : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Text(
        isVip ? 'VIP' : 'Standard',
        style: TextStyle(
          color: isVip ? const Color(0xFFB8860B) : Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
