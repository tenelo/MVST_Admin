import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TicketsDuJour extends StatefulWidget {
  const TicketsDuJour({
    super.key,
    required this.gare,
    required this.destination,
    required this.uid,
    required this.date,
    required this.idDoc,
    this.typeDepart = '',
  });
  final String gare;
  final String destination;
  final String uid;
  final String date;
  final String idDoc;
  final String typeDepart;

  @override
  State<TicketsDuJour> createState() => _TicketsDuJourState();
}

class _TicketsDuJourState extends State<TicketsDuJour> {
  int _rowsPerPage = 20;
  bool _isLoading = true;
  List<Map<String, dynamic>> donnees = [];
  List<Map<String, dynamic>> _filtre = [];
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();
  final TextEditingController _rechercheParNom = TextEditingController();

  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _getDonnees();
    _connecterSocket();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _rechercheParDate.dispose();
    _rechercheParDestination.dispose();
    _rechercheParNom.dispose();
    super.dispose();
  }

  // ── Connexion Socket.IO ────────────────────────────────────────────────────
  void _connecterSocket() {
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket.connect();

    socket.onConnect((_) {
      socket.emit('rejoindre_room', {
        'depart': widget.gare,
        'date': widget.date,
      });
    });

    // ── Nouveau ticket acheté → rafraîchir ────────────────────────────────
    socket.on('liste_mise_a_jour', (data) {
      if (data['documentId'] == widget.idDoc) {
        _getDonnees();
      }
    });
  }

  // ── Charger les tickets via PHP ────────────────────────────────────────────
  Future<void> _getDonnees() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        'ticketsDuJour.php',
        body: {'documentId': widget.idDoc, 'gare': widget.gare},
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
    final c = Config.colors;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.authCardBackground),
        toolbarHeight: 64,
        title: Text(
          '${widget.gare} -> ${widget.destination} ${widget.date.replaceAll('_', ' ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: c.authCardBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 18, color: c.authCardBackground),
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
              padding: const EdgeInsets.symmetric(vertical: 4),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.typeDepart.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: _TypeBadge(
                                        type: widget.typeDepart,
                                      ),
                                    ),
                                  Text(
                                    "NOMBRE TOTAL DE TICKETS : ${donnees.length}",
                                    style: TextStyle(
                                      color: Config.colors.authCardBackground,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          Text(
            formatHeure(ticket['heure']?.toString() ?? ''),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          Text(
            ticket['depart'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          Text(
            ticket['destination'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          Text(
            ticket['place'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          Text(
            ticket['prixDuTicket'].toString(),
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          Text(ticket['nom'].toString(), style: const TextStyle(fontSize: 13)),
          onTap: () => _onTapRow(ticket),
        ),
        DataCell(
          _TypeBadge(type: ticket['typeVoyage']?.toString() ?? 'standard'),
          onTap: () => _onTapRow(ticket),
        ),
      ],
    );
  }

  void _onTapRow(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsTickets(
          idTicket: ticket['documentId'].toString(),
          idUtilisateur: ticket['idUtilisateur'].toString(),
          nom: ticket['nom'].toString(),
          contact: ticket['telephone'].toString(),
          date: ticket['date'].toString(),
          heure: ticket['heure'].toString(),
          depart: ticket['depart'].toString(),
          destination: ticket['destination'].toString(),
          place: ticket['place'],
          etatScann: ticket['etatScanne'].toString(),
          statut: ticket['statut'].toString(),
          prixTicket: ticket['prixDuTicket'].toString(),
          datePourCalcule: ticket['datePourCalcule'] != null
              ? DateTime.parse(ticket['datePourCalcule'].toString())
              : DateTime.now(),
          typeVoyage: ticket['typeVoyage'].toString(),
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
