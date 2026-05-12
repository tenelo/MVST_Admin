import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/graphiques/graphiqueJourDepart/graphiqueJourDepart.dart';
import 'package:mvst_admin/screens/placesAssisesStandard.dart';
import 'package:mvst_admin/screens/ticketsDuJour.dart';
import 'package:mvst_admin/screens/vip/placesAssisesVIP.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

List<String> listeDesHeures = [];
String? heuresFormattees;

class TousLesDepartsDuJour extends StatefulWidget {
  const TousLesDepartsDuJour({
    super.key,
    required this.gare,
    required this.uid,
    required this.date,
    required this.dateNormale,
    required this.tailleEcran,
  });
  final String gare;
  final String uid;
  final String date;
  final String dateNormale;
  final int tailleEcran;

  @override
  State<TousLesDepartsDuJour> createState() => _TousLesDepartsDuJourState();
}

class _TousLesDepartsDuJourState extends State<TousLesDepartsDuJour> {
  List<Map<String, dynamic>> departs = [];
  bool _isLoading = true;
  int _activeTab = 0; // 0=Tous, 1=Standard, 2=VIP

  List<Map<String, dynamic>> get _departsFiltres {
    if (_activeTab == 0) return departs;
    if (_activeTab == 1) {
      return departs
          .where(
            (d) =>
                (d['typeVoyage']?.toString().toLowerCase() ?? 'standard') !=
                'vip',
          )
          .toList();
    }
    return departs
        .where((d) => d['typeVoyage']?.toString().toLowerCase() == 'vip')
        .toList();
  }

  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _chargerDeparts();
    _connecterSocket();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket.connect();

    // ── Nouveau ticket acheté → rafraîchir ────────────────────────────────
    socket.on('liste_mise_a_jour', (data) {
      if (data['depart'] == widget.gare) {
        _chargerDeparts();
      }
    });
  }

  Future<void> _chargerDeparts() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/departsParGare.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'date': widget.date, 'gare': widget.gare}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final liste = List<Map<String, dynamic>>.from(data['departs']);

          // Calculer les heures formatées
          listeDesHeures = liste
              .map((d) => '${d['heureDeDepart']} h')
              .toSet()
              .toList();
          heuresFormattees = liste
              .map((d) => d['heureDeDepart'].toString())
              .join(' | ');

          if (mounted) {
            setState(() {
              departs = liste;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
        title: Text(
          'Départs',
          style: TextStyle(
            color: Config.colors.authCardBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Config.colors.authCardBackground),
            onPressed: _chargerDeparts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : departs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  'Aucun ticket pris pour le départ du ${widget.dateNormale}',
                  style: TextStyle(
                    color: Config.colors.authCardBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                // ── Résumé du jour ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.blueGrey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Le ${widget.dateNormale}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "Départs: ${departs.length}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              'Std ${departs.where((d) => (d['typeVoyage']?.toString().toLowerCase() ?? '') != 'vip').length}',
                              false,
                            ),
                            const SizedBox(width: 4),
                            _buildTypeChip(
                              'VIP ${departs.where((d) => d['typeVoyage']?.toString().toLowerCase() == 'vip').length}',
                              true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Heures: $heuresFormattees",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Filtre VIP / Standard ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: _activeTab == 0,
                        onSelected: (_) => setState(() => _activeTab = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Standard'),
                        selected: _activeTab == 1,
                        selectedColor: Colors.blue.shade100,
                        onSelected: (_) => setState(() => _activeTab = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('VIP'),
                        selected: _activeTab == 2,
                        selectedColor: const Color(
                          0xFFFFD700,
                        ).withValues(alpha: 0.4),
                        onSelected: (_) => setState(() => _activeTab = 2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 4,
                      top: 2,
                      right: 2,
                      bottom: 4,
                    ),
                    itemCount: _departsFiltres.length,
                    itemBuilder: (context, index) {
                      final typeVoyage =
                          _departsFiltres[index]['typeVoyage']?.toString() ??
                          'standard';
                      return (widget.tailleEcran <= 6)
                          ? _CartePetitEcran(
                              context,
                              widget.gare,
                              widget.uid,
                              _departsFiltres[index]['heureDeDepart'],
                              _departsFiltres[index]['nombreDePlacesChoisies'] ??
                                  0,
                              _departsFiltres[index]['documentId'],
                              _departsFiltres[index]['depart'],
                              _departsFiltres[index]['destination'],
                              _departsFiltres[index]['dateDeDepart'],
                              widget.dateNormale,
                              typeVoyage,
                            )
                          : _CarteGrandEcran(
                              context,
                              widget.gare,
                              widget.uid,
                              _departsFiltres[index]['heureDeDepart'],
                              _departsFiltres[index]['nombreDePlacesChoisies'] ??
                                  0,
                              _departsFiltres[index]['documentId'],
                              _departsFiltres[index]['depart'],
                              _departsFiltres[index]['destination'],
                              _departsFiltres[index]['dateDeDepart'],
                              widget.dateNormale,
                              typeVoyage,
                            );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTypeChip(String label, bool isVip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVip
            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
            : Colors.blue.shade700.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVip ? const Color(0xFFFFD700) : Colors.blue.shade200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isVip ? const Color(0xFFFFD700) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Carte petit écran ─────────────────────────────────────────────────────────
Widget _CartePetitEcran(
  BuildContext context,
  String gare,
  String uid,
  String heures,
  int nombrePlacesChoisies,
  String documentId,
  String depart,
  String destination,
  String idDate,
  String date,
  String typeVoyage,
) {
  final bool isVip = typeVoyage.toLowerCase() == 'vip';
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 5,
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 68, 190, 255),
            Color.fromARGB(108, 5, 82, 121),
            Color.fromARGB(255, 53, 96, 237),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Départ de : $heures h",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (isVip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 12,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'VIP',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "Nombre de passagers : ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: "$nombrePlacesChoisies",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _bouton(context, "Les destinations", Icons.bar_chart_sharp, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraphiqueJourDepart(
                      documentId: documentId,
                      date: date,
                      gare: gare,
                      uid: uid,
                    ),
                  ),
                );
              }),
              _bouton(context, "Les tickets", Icons.receipt_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketsDuJour(
                      date: date,
                      idDoc: documentId,
                      gare: gare,
                      uid: uid,
                      typeDepart: typeVoyage,
                    ),
                  ),
                );
              }),
              _bouton(context, "Les Places", Icons.event_seat, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => isVip
                        ? PlacesAssisesVIP(
                            documentId: documentId,
                            depart: depart,
                            destination: destination,
                            heure: heures,
                          )
                        : PlacesAssises(
                            documentId: documentId,
                            depart: depart,
                            destination: destination,
                            heure: heures,
                          ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── Carte grand écran ─────────────────────────────────────────────────────────
Widget _CarteGrandEcran(
  BuildContext context,
  String gare,
  String uid,
  String heures,
  int nombrePlacesChoisies,
  String documentId,
  String depart,
  String destination,
  String idDate,
  String date,
  String typeVoyage,
) {
  final bool isVip = typeVoyage.toLowerCase() == 'vip';
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 5,
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 68, 190, 255),
            Color.fromARGB(108, 5, 82, 121),
            Color.fromARGB(255, 53, 96, 237),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Départ de : $heures h",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (isVip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 12,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'VIP',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "Nombre de passagers : ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: "$nombrePlacesChoisies",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bouton(context, "Les destinations", Icons.bar_chart_sharp, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraphiqueJourDepart(
                      documentId: documentId,
                      date: date,
                      gare: gare,
                      uid: uid,
                    ),
                  ),
                );
              }),
              _bouton(context, "Places occupées", Icons.event_seat, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlacesAssises(
                      documentId: documentId,
                      depart: depart,
                      destination: destination,
                      heure: heures,
                    ),
                  ),
                );
              }),
              _bouton(context, "Les tickets", Icons.receipt_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketsDuJour(
                      date: date,
                      idDoc: documentId,
                      gare: gare,
                      uid: uid,
                      typeDepart: typeVoyage,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── Bouton réutilisable ───────────────────────────────────────────────────────
Widget _bouton(
  BuildContext context,
  String label,
  IconData icon,
  VoidCallback onPressed,
) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Icon(icon, color: Colors.orange),
      ],
    ),
  );
}
