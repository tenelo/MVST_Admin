import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TicketsDuJourScannes extends StatefulWidget {
  const TicketsDuJourScannes({
    super.key,
    required this.gare,
    required this.uid,
    required this.date,
  });
  final String gare;
  final String uid;
  final String date;

  @override
  State<TicketsDuJourScannes> createState() => _TicketsDuJourScannesState();
}

class _TicketsDuJourScannesState extends State<TicketsDuJourScannes> {
  int _rowsPerPage = 20;
  bool _isLoading = true;
  int _activeTab = 0; // 0=Tous, 1=Standard, 2=VIP
  late DateTime _dateSelectionnee;
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
    _dateSelectionnee = _parseDate(widget.date);
    _getDonnees();
    _connecterSocket();
  }

  DateTime _parseDate(String s) {
    try {
      return DateFormat('EEEE_d_MMMM_y', 'fr_FR').parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  String get _dateApiSocket =>
      DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(_dateSelectionnee);

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null && mounted) {
      final ancienneDate = _dateApiSocket;
      setState(() {
        _dateSelectionnee = picked;
      });
      socket.emit('quitter_room', {'depart': widget.gare, 'date': ancienneDate});
      socket.emit('rejoindre_room', {
        'depart': widget.gare,
        'date': _dateApiSocket,
      });
      _getDonnees();
    }
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
        'date': _dateApiSocket,
      });
    });

    // ── Un ticket vient d'être scanné → rafraîchir la liste ────────────────
    socket.on('ticket_valide', (data) {
      if (data['depart'] == widget.gare || mounted) {
        _getDonnees();
      }
    });
  }

  // ── Charger les tickets scannés via PHP ────────────────────────────────────
  Future<void> _getDonnees() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final String dateDuJour =
          DateFormat('yyyy-MM-dd').format(_dateSelectionnee);

      final response = await ApiClient.instance.post(
        'ticketsDuJourScannes.php',
        body: {'date': dateDuJour, 'gare': widget.gare},
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
        final type = data['typeVoyage']?.toString().toLowerCase() ?? 'standard';
        final matchType =
            _activeTab == 0 ||
            (_activeTab == 1 && type != 'vip') ||
            (_activeTab == 2 && type == 'vip');
        return matchType &&
            data['date'].toString().toLowerCase().contains(searchDate) &&
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
          "Tickets scannés du jour",
          style: TextStyle(
            fontSize: 14,
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
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rechercheParDate,
                      decoration: const InputDecoration(
                        hintText: 'Recherche\npar date',
                        hintMaxLines: 2,
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
                        hintText: 'Recherche\npar destination',
                        hintMaxLines: 2,
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
                        hintText: 'Recherche\npar nom',
                        hintMaxLines: 2,
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
            // ── Filtres VIP / Standard ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Tous'),
                    selected: _activeTab == 0,
                    onSelected: (_) {
                      setState(() => _activeTab = 0);
                      _filtrerDonnees();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Standard'),
                    selected: _activeTab == 1,
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) {
                      setState(() => _activeTab = 1);
                      _filtrerDonnees();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('VIP'),
                    selected: _activeTab == 2,
                    selectedColor: const Color(
                      0xFFFFD700,
                    ).withValues(alpha: 0.4),
                    onSelected: (_) {
                      setState(() => _activeTab = 2);
                      _filtrerDonnees();
                    },
                  ),
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
                                "TICKETS SCANNÉS : ${donnees.length}",
                                style: TextStyle(
                                  color: Config.colors.authCardBackground,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            horizontalMargin: 5,
                            columnSpacing: 20,
                            showFirstLastButtons: true,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Date',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Heure',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Départ',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Destination',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Place',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 9, 15, 123),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Client',
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
          date: ConvertirHeure.formatDate(ticket['date'].toString()),
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
