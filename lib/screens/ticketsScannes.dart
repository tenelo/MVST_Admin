import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/screens/detailsTickets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ticket_material/ticket_material.dart';

class TicketsScannes extends StatefulWidget {
  const TicketsScannes({super.key, required this.documentId});
  final String documentId;

  @override
  State<TicketsScannes> createState() => _TicketsScannesState();
}

class _TicketsScannesState extends State<TicketsScannes> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];

  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
    _getDonnees();
    _connecterSocket();
  }

  @override
  void dispose() {
    _searchController.dispose();
    socket.disconnect();
    socket.dispose();
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

    // ── Un ticket vient d'être scanné → rafraîchir ────────────────────────
    socket.on('ticket_valide', (data) {
      if (data['documentId'] == widget.documentId) {
        _getDonnees();
      }
    });
  }

  // ── Charger les tickets scannés via PHP ────────────────────────────────────
  Future<void> _getDonnees() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await http.post(
        apiUri('mesTicketsScannes.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'documentId': widget.documentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _tickets = List<Map<String, dynamic>>.from(data['tickets']);
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterTickets(
    List<Map<String, dynamic>> tickets,
  ) {
    if (_searchText.isEmpty) return tickets;
    return tickets.where((ticket) {
      return ticket['nom'].toString().toLowerCase().contains(_searchText) ||
          ticket['telephone'].toString().toLowerCase().contains(_searchText) ||
          ticket['date'].toString().toLowerCase().contains(_searchText) ||
          ticket['depart'].toString().toLowerCase().contains(_searchText) ||
          ticket['destination'].toString().toLowerCase().contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tailleEcran = Calcule.tailleEcran(context).round();
    final filteredTickets = _filterTickets(_tickets);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
        centerTitle: true,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: TextStyle(color: Colors.grey[600]),
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
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Config.colors.authCardBackground),
            onPressed: _getDonnees,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Config.colors.authCardBackground,
                  ),
                )
              : filteredTickets.isEmpty
              ? Center(
                  child: Text(
                    "Aucun ticket scanné",
                    style: TextStyle(
                      color: Config.colors.authCardBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredTickets.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ticket = filteredTickets[index];
                    final date = DateFormat(
                      'EEEE d MMMM yyyy',
                      'fr_FR',
                    ).parse(ticket['date']);
                    final dateFormatee = DateFormat(
                      'EEEE d MMMM y',
                      'fr_FR',
                    ).format(date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TicketMaterial(
                        height: 115,
                        colorBackground: const Color.fromARGB(108, 5, 82, 121),
                        colorShadow: Colors.white,
                        shadowSize: 2,
                        radiusBorder: 8,
                        leftChild: _buildLeft(
                          context,
                          ticket['documentId'].toString(),
                          ticket['idUtilisateur'].toString(),
                          ticket['nom'].toString(),
                          ticket['telephone'].toString(),
                          dateFormatee,
                          ticket['heure'].toString(),
                          ticket['depart'].toString(),
                          ticket['destination'].toString(),
                          ticket['place'],
                          ticket['etatScanne'].toString(),
                          ticket['prixDuTicket'].toString(),
                          ticket['statut'].toString(),
                          ticket['datePourCalcule'] != null
                              ? DateTime.parse(
                                  ticket['datePourCalcule'].toString(),
                                )
                              : DateTime.now(),
                          tailleEcran,
                          ticket['typeVoyage'],
                        ),
                        rightChild: _buildRight(),
                        tapHandler: () {},
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildLeft(
    BuildContext context,
    String idTicket,
    String idUtilisateur,
    String nom,
    String contact,
    String date,
    String heure,
    String depart,
    String destination,
    int numeroDePlace,
    String etatScann,
    String prixTicket,
    String statut,
    DateTime dateCalcule,
    int tailleEcran,
    String typeVoyage,
  ) {
    return GestureDetector(
      onTap: () {
        if (tailleEcran >= 6) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsTickets(
                idTicket: idTicket,
                idUtilisateur: idUtilisateur,
                nom: nom,
                contact: contact,
                date: date,
                heure: heure,
                depart: depart,
                destination: destination,
                place: numeroDePlace,
                etatScann: etatScann,
                statut: statut,
                prixTicket: prixTicket,
                datePourCalcule: dateCalcule,
                typeVoyage: typeVoyage,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsTickets(
                idTicket: idTicket,
                idUtilisateur: idUtilisateur,
                nom: nom,
                contact: contact,
                date: date,
                heure: heure,
                depart: depart,
                destination: destination,
                place: numeroDePlace,
                etatScann: etatScann,
                statut: statut,
                prixTicket: prixTicket,
                datePourCalcule: dateCalcule,
                typeVoyage: typeVoyage,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, right: 2, bottom: 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Départ du : "),
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Heure de départ : "),
                Text(
                  heure,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Siège : "),
                Text(
                  "N° $numeroDePlace",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Center(
                child: SizedBox(
                  height: 32,
                  child: TextButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (tailleEcran >= 6) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets(
                              idTicket: idTicket,
                              idUtilisateur: idUtilisateur,
                              nom: nom,
                              contact: contact,
                              date: date,
                              heure: heure,
                              depart: depart,
                              destination: destination,
                              place: numeroDePlace,
                              etatScann: etatScann,
                              statut: statut,
                              prixTicket: prixTicket,
                              datePourCalcule: dateCalcule,
                              typeVoyage: typeVoyage,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets(
                              idTicket: idTicket,
                              idUtilisateur: idUtilisateur,
                              nom: nom,
                              contact: contact,
                              date: date,
                              heure: heure,
                              depart: depart,
                              destination: destination,
                              place: numeroDePlace,
                              etatScann: etatScann,
                              statut: statut,
                              prixTicket: prixTicket,
                              datePourCalcule: dateCalcule,
                              typeVoyage: typeVoyage,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Voir les détails",
                      style: TextStyle(color: Colors.white),
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

  Widget _buildRight() {
    return const Padding(
      padding: EdgeInsets.all(2.0),
      child: RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            "MVST",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
