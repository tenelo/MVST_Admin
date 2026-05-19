import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/models/models.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

List<PlacesTickets> maListeDeTickets = [];

class PlacesAssises extends StatefulWidget {
  const PlacesAssises({
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
  State<PlacesAssises> createState() => _PlacesAssisesState();
}

class _PlacesAssisesState extends State<PlacesAssises> {
  bool _isLoading = true;
  String? _errorMessage;

  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  @override
  void dispose() {
    maListeDeTickets.clear();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  // ── Charger les places via PHP ─────────────────────────────────────────────
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
              maListeDeTickets = List<Map<String, dynamic>>.from(data['places'])
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

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final hauteurEcran = MediaQuery.of(context).size.height;
    final bool petitEcran = largeurEcran < 600;

    return Scaffold(
      backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      appBar: AppBar(
        toolbarHeight: hauteurEcran * 0.06,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${widget.heure} h",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: largeurEcran * 0.040,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(132, 5, 82, 121),
        // ── Bouton rafraîchir manuel ──────────────────────────────────────
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: chargerDonnees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _errorMessage != null
          ? const Center(child: Text('Erreur'))
          : Container(
              color: const Color.fromARGB(69, 191, 217, 248),
              child: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: petitEcran
                        ? hauteurEcran * 0.90
                        : hauteurEcran * 0.85,
                    width: petitEcran
                        ? largeurEcran * 0.82
                        : largeurEcran * 0.76,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Config.colors.jauneBlanc),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: const Color.fromARGB(168, 191, 217, 248),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Places(numero: 61, heure: widget.heure),
                                  Places(numero: 60, heure: widget.heure),
                                  Places(numero: 59, heure: widget.heure),
                                  Places(numero: 58, heure: widget.heure),
                                  Places(numero: 57, heure: widget.heure),
                                  Places(numero: 56, heure: widget.heure),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Places(
                                            numero: 55,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 54,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 50,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 49,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 45,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 44,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 40,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 39,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: porte(),
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 35,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 34,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 30,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 29,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 25,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 24,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 20,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 19,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 15,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 14,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 10,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 9,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 5,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 4,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: largeurEcran * 0.09),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Places(
                                            numero: 53,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 52,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 51,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 48,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 47,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 46,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 43,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 42,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 41,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 38,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 37,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 36,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 33,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 32,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 31,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 28,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 27,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 26,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 23,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 22,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 21,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 18,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 17,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 16,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 13,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 12,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 11,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 8,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 7,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 6,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(
                                            numero: 3,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 2,
                                            heure: widget.heure,
                                          ),
                                          Places(
                                            numero: 1,
                                            heure: widget.heure,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: largeurEcran * 0.155),
                                          PlacesChauffeur(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [porte()],
                                  ),
                                  SizedBox(width: largeurEcran * 0.385),
                                  Column(
                                    children: [
                                      Container(
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

// ── Widget Places (admin) ─────────────────────────────────────────────────────
class Places extends StatefulWidget {
  const Places({super.key, required this.numero, required this.heure});
  final int numero;
  final String heure;

  @override
  State<Places> createState() => _PlacesState();
}

class _PlacesState extends State<Places> {
  Color couleurSelection = const Color.fromARGB(255, 182, 214, 251);
  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);
  bool isLoading = false;
  String etat = "nonCliquable";

  @override
  void initState() {
    super.initState();
    verification();
  }

  void verification() {
    if (maListeDeTickets.isNotEmpty) {
      if (maListeDeTickets.any((ticket) => ticket.place == widget.numero)) {
        setState(() {
          couleurInitiale = couleurSelection;
          etat = "cliquable";
        });
      }
    }
  }

  Future<void> _afficherInfos() async {
    var ticket = maListeDeTickets.firstWhere(
      (ticket) => ticket.place == widget.numero,
    );
    showRichTextDialog(
      context,
      ticket.nom,
      ticket.telephone,
      ticket.depart,
      ticket.destination,
      widget.heure,
      ticket.place,
    );
  }

  List<bool> selection = List.filled(62, false);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool petitEcran = w < 600;

    // ── Mise à jour temps réel ─────────────────────────────────────────────
    if (maListeDeTickets.any((t) => t.place == widget.numero) &&
        etat == "nonCliquable") {
      couleurInitiale = couleurSelection;
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
        margin: EdgeInsets.all(petitEcran ? 0.5 : 1.0),
        padding: EdgeInsets.all(petitEcran ? 0.5 : 0.8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Card(
                color: selection[widget.numero % 62]
                    ? couleurSelection
                    : couleurInitiale,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  height: w * 0.092,
                  width: w * 0.092,
                  child: Center(
                    child: Text(
                      widget.numero.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            // ― côtés ―
            Positioned(
              left: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.053, width: w * 0.014),
              ),
            ),
            Positioned(
              right: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.053, width: w * 0.014),
              ),
            ),
            // ― dessus ―
            Positioned(
              top: -4,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.016, width: w * 0.067),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget PlacesChauffeur (admin) ────────────────────────────────────────────
class PlacesChauffeur extends StatelessWidget {
  PlacesChauffeur({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.all(0.5),
      padding: const EdgeInsets.all(0.8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: Config.colors.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: w * 0.092,
              width: w * 0.092,
              child: const Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.053, width: w * 0.014),
            ),
          ),
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.053, width: w * 0.014),
            ),
          ),
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.016, width: w * 0.067),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Porte ──────────────────────
Widget porte() {
  return Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 23,
        width: 8,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 24,
        width: 10,
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(
            color: const Color.fromARGB(255, 89, 87, 87),
            width: 1,
          ),
        ),
        height: 25,
        width: 12,
      ),
    ],
  );
}

// ── Dialogue d'informations  ───────────────────────────────────────
// ── Nouveau dialogue stylé ─────────────────────────────────────────────────
Future<void> showRichTextDialog(
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              // ── En-tête avec dégradé et titre ─────────────────────────
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
                    colors: [
                      Color(0xFF1565C0), // bleu foncé
                      Color(0xFF1976D2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_pin_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Détails du passager',
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

              // ── Corps du dialogue ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Itinéraire
                    _buildInfoRow(
                      icon: Icons.route,
                      iconColor: const Color(0xFF1565C0),
                      label: 'Trajet',
                      value: '$depart → $destination $heure h',
                      isBold: true,
                    ),
                    const Divider(height: 24),

                    // Nom
                    _buildInfoRow(
                      icon: Icons.person,
                      iconColor: Colors.grey[700]!,
                      label: 'Passager',
                      value: nom,
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    _buildInfoRow(
                      icon: Icons.phone_android,
                      iconColor: Colors.grey[700]!,
                      label: 'Téléphone',
                      value: telephone,
                    ),
                    const SizedBox(height: 24),

                    // Place (mise en évidence)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD), // bleu très clair
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_seat,
                              color: Color(0xFF1565C0),
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
                                color: Color(0xFF0D47A1), // bleu profond
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

              // ── Bouton de fermeture ────────────────────────────────────
              Container(
                padding: const EdgeInsets.only(bottom: 12, right: 16),
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF1565C0),
                  ),
                  label: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFF1565C0)),
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

// ── Helper pour une ligne d'info avec icône ──────────────────────────────────
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
                color: isBold ? const Color(0xFF0D47A1) : Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
