import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/models/models.dart';

List<PlacesTickets> maListeDeTicketsVIP = [];

// ── Couleurs VIP ─────────────────────────────────────────────────────────────
const Color _vipOr = Color(0xFF00D87E);
const Color _vipSiegeDispo = Color.fromARGB(226, 1, 80, 40);
const Color _vipSiegeOccupe = Color(0xFF00D87E);

class CarVIP extends StatefulWidget {
  const CarVIP({
    super.key,
    required this.documentId,
    required this.depart,
    required this.destination,
    required this.heure,
  });
  final String documentId;
  final String depart;
  final String destination;
  final String heure;

  @override
  State<CarVIP> createState() => _CarVIPState();
}

class _CarVIPState extends State<CarVIP> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  @override
  void dispose() {
    maListeDeTicketsVIP.clear();
    super.dispose();
  }

  Future<void> chargerDonnees() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

    try {
      final response = await http.post(
        apiUri('placesAssises.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'documentId': widget.documentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              maListeDeTicketsVIP =
                  List<Map<String, dynamic>>.from(data['places'])
                      .map(
                        (p) => PlacesTickets(
                          nom: p['nom'].toString(),
                          telephone: p['telephone'].toString(),
                          depart: p['depart'].toString(),
                          destination: p['destination'].toString(),
                          place: int.parse(p['place'].toString()),
                        ),
                      )
                      .toList();
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur';
        });
    }
  }

  Widget _rangee2(List<int> numeros) {
    return Row(
      children: numeros
          .map((n) => PlacesVIP(numero: n, heure: widget.heure))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final hauteurEcran = MediaQuery.of(context).size.height;
    final bool petitEcran = largeurEcran < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        toolbarHeight: hauteurEcran * 0.06,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${formatHeure(widget.heure)}",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: largeurEcran * 0.040,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 1, 110, 64),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: chargerDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _vipOr))
          : _errorMessage != null
          ? const Center(child: Text('Erreur'))
          : Container(
              color: const Color(0xFFF0FBF5),
              child: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: petitEcran
                        ? largeurEcran * 0.72
                        : largeurEcran * 0.76,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _vipOr, width: 1.5),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: const Color.fromARGB(255, 227, 252, 237),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              // ── DERNIÈRE RANGÉE ──────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _rangee2([50, 49]),
                                  SizedBox(width: largeurEcran * 0.09),
                                  _rangee2([48, 47]),
                                ],
                              ),
                              // ── CORPS DU BUS VIP 2+2 ─────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── RANGÉE GAUCHE ─────────────────────
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _rangee2([41, 42]),
                                      _rangee2([37, 38]),
                                      _rangee2([33, 34]),
                                      _rangee2([29, 30]),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                          bottom: 8.0,
                                          left: 8.0,
                                        ),
                                        child: porte(),
                                      ),
                                      _rangee2([25, 26]),
                                      _rangee2([21, 22]),
                                      _rangee2([17, 18]),
                                      _rangee2([13, 14]),
                                      _rangee2([9, 10]),
                                      _rangee2([5, 6]),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          top: 10.0,
                                        ),
                                        child: porte(),
                                      ),
                                    ],
                                  ),
                                  // ── COULOIR ───────────────────────────
                                  SizedBox(width: largeurEcran * 0.09),
                                  // ── RANGÉE DROITE ─────────────────────
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _rangee2([45, 46]),
                                      _rangee2([43, 44]),
                                      _rangee2([39, 40]),
                                      _rangee2([35, 36]),
                                      _rangee2([31, 32]),
                                      const SizedBox(height: 4),
                                      _rangee2([27, 28]),
                                      _rangee2([23, 24]),
                                      _rangee2([19, 20]),
                                      _rangee2([15, 16]),
                                      _rangee2([11, 12]),
                                      _rangee2([7, 8]),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const SizedBox(width: 10),
                                          PlacesVIPChauffeur(),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Container(
                                          height: largeurEcran * 0.10,
                                          width: largeurEcran * 0.13,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                'assets/images/volant4_sf.png',
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Widget Places VIP ─────────────────────────────────────────────────────────
class PlacesVIP extends StatefulWidget {
  const PlacesVIP({super.key, required this.numero, required this.heure});
  final int numero;
  final String heure;

  @override
  State<PlacesVIP> createState() => _PlacesVIPState();
}

class _PlacesVIPState extends State<PlacesVIP> {
  Color couleurInitiale = _vipSiegeDispo;
  bool isLoading = false;
  String etat = "nonCliquable";

  @override
  void initState() {
    super.initState();
    verification();
  }

  void verification() {
    if (maListeDeTicketsVIP.isNotEmpty) {
      if (maListeDeTicketsVIP.any((ticket) => ticket.place == widget.numero)) {
        setState(() {
          couleurInitiale = _vipSiegeOccupe;
          etat = "cliquable";
        });
      }
    }
  }

  Future<void> _afficherInfos() async {
    var ticket = maListeDeTicketsVIP.firstWhere(
      (ticket) => ticket.place == widget.numero,
    );
    _showRichTextDialog(
      context,
      ticket.nom,
      ticket.telephone,
      ticket.depart,
      ticket.destination,
      widget.heure,
      ticket.place,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool petitEcran = w < 600;
    final double siegeSize = petitEcran ? w * 0.090 : w * 0.093;

    final Color textColor = etat == "cliquable"
        ? Colors.white
        : const Color(0xFF006B3C);

    if (maListeDeTicketsVIP.any((t) => t.place == widget.numero) &&
        etat == "nonCliquable") {
      couleurInitiale = _vipSiegeOccupe;
      etat = "cliquable";
    }

    return GestureDetector(
      onTap: () async {
        if (etat == "cliquable") {
          setState(() => isLoading = true);
          await _afficherInfos();
          setState(() => isLoading = false);
        }
      },
      child: Container(
        margin: EdgeInsets.all(w * 0.003),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: siegeSize,
                width: siegeSize,
                child: const CircularProgressIndicator(
                  color: _vipOr,
                  strokeWidth: 2,
                ),
              )
            else
              Card(
                color: couleurInitiale,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: etat == "cliquable" ? Colors.transparent : _vipOr,
                    width: 0.5,
                  ),
                ),
                child: SizedBox(
                  height: siegeSize,
                  width: siegeSize,
                  child: Center(
                    child: Text(
                      widget.numero.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: w * 0.030,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: -w * 0.005,
              child: Card(
                color: _vipOr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: siegeSize * 0.5, width: w * 0.015),
              ),
            ),
            Positioned(
              right: -w * 0.005,
              child: Card(
                color: _vipOr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: siegeSize * 0.5, width: w * 0.015),
              ),
            ),
            Positioned(
              top: -w * 0.008,
              child: Card(
                color: _vipOr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.015, width: siegeSize * 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogue d'informations VIP ──────────────────────────────────────────
  Future<void> _showRichTextDialog(
    BuildContext context,
    String nom,
    String telephone,
    String depart,
    String destination,
    String heure,
    int place,
  ) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 50,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── En-tête ─────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      colors: [Color(0xFF006B3C), _vipOr],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Détails du passager VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Corps ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoRow(
                        icon: Icons.route,
                        iconColor: _vipOr,
                        label: 'Trajet',
                        value: '$depart → $destination ${formatHeure(heure)}',
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.person,
                        iconColor: Colors.grey[700]!,
                        label: 'Passager',
                        value: nom,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.phone_android,
                        iconColor: Colors.grey[700]!,
                        label: 'Téléphone',
                        value: telephone,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _vipOr.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_seat,
                                color: _vipOr,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Place N°',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$place',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF006B3C),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Bouton fermeture ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.only(bottom: 12, right: 16),
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_outline, color: _vipOr),
                    label: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _vipOr,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: _vipOr),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helper ligne d'info ──────────────────────────────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: isBold ? 17 : 16,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isBold ? _vipOr : Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Widget PlacesVIPChauffeur ──────────────────────────────────────────────────
class PlacesVIPChauffeur extends StatelessWidget {
  const PlacesVIPChauffeur({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool petitEcran = w < 600;
    final double siegeSize = petitEcran ? w * 0.085 : w * 0.090;

    return Container(
      margin: EdgeInsets.all(w * 0.003),
      padding: EdgeInsets.all(w * 0.002),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: Config.colors.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(height: siegeSize, width: siegeSize),
          ),
          Positioned(
            left: -w * 0.005,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: siegeSize * 0.5, width: w * 0.015),
            ),
          ),
          Positioned(
            right: -w * 0.005,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: siegeSize * 0.5, width: w * 0.015),
            ),
          ),
          Positioned(
            top: -w * 0.008,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.015, width: siegeSize * 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
