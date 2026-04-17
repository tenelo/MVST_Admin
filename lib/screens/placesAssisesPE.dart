import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
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
    _connecterSocket();
  }

  @override
  void dispose() {
    maListeDeTickets.clear();
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

    socket.onConnect((_) {
      // Rejoindre la Room du départ
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'date': widget.documentId,
      });
    });

    // ── Une place vient d'être achetée → rafraîchir ────────────────────────
    socket.on('liste_mise_a_jour', (data) {
      if (data['documentId'] == widget.documentId) {
        chargerDonnees();
      }
    });

    // ── Une place vient d'être prise → rafraîchir ──────────────────────────
    socket.on('place_prise', (data) {
      chargerDonnees();
    });
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
        Uri.parse('https://mvst.tenelo.cloud/placesAssises.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'documentId': widget.documentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              maListeDeTickets = List<Map<String, dynamic>>.from(data['places'])
                  .map((p) => PlacesTickets(
                        nom: p['nom'].toString(),
                        telephone: p['telephone'].toString(),
                        depart: p['depart'].toString(),
                        destination: p['destination'].toString(),
                        place: int.parse(p['place'].toString()),
                      ))
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      appBar: AppBar(
        toolbarHeight: 40,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${widget.heure} h",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
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
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.80,
                      width: MediaQuery.of(context).size.width * 0.70,
                      child: Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Config.colors.jauneBlanc),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50)),
                            color: const Color.fromARGB(168, 191, 217, 248),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PlacesReservees(numero: 61),
                                    PlacesReservees(numero: 60),
                                    PlacesReservees(numero: 59),
                                    PlacesReservees(numero: 58),
                                    PlacesReservees(numero: 57),
                                    PlacesReservees(numero: 56),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(children: [
                                          Places(numero: 55),
                                          Places(numero: 54)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 50),
                                          Places(numero: 49)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 45),
                                          Places(numero: 44)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 40),
                                          Places(numero: 39)
                                        ]),
                                        porte(),
                                        const SizedBox(height: 1),
                                        const Row(children: [
                                          Places(numero: 35),
                                          Places(numero: 34)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 30),
                                          Places(numero: 29)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 25),
                                          Places(numero: 24)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 20),
                                          Places(numero: 19)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 15),
                                          Places(numero: 14)
                                        ]),
                                        const Row(children: [
                                          Places(numero: 10),
                                          Places(numero: 9)
                                        ]),
                                        Row(children: [
                                          PlacesReservees(numero: 5),
                                          PlacesReservees(numero: 4)
                                        ]),
                                      ],
                                    ),
                                    const SizedBox(width: 35),
                                    Column(
                                      children: [
                                        Row(children: [
                                          Places(numero: 53),
                                          Places(numero: 52),
                                          Places(numero: 51)
                                        ]),
                                        Row(children: [
                                          Places(numero: 48),
                                          Places(numero: 47),
                                          Places(numero: 46)
                                        ]),
                                        Row(children: [
                                          Places(numero: 43),
                                          Places(numero: 42),
                                          Places(numero: 41)
                                        ]),
                                        Row(children: [
                                          Places(numero: 38),
                                          Places(numero: 37),
                                          Places(numero: 36)
                                        ]),
                                        Row(children: [
                                          Places(numero: 33),
                                          Places(numero: 32),
                                          Places(numero: 31)
                                        ]),
                                        Row(children: [
                                          Places(numero: 28),
                                          Places(numero: 27),
                                          Places(numero: 26)
                                        ]),
                                        Row(children: [
                                          Places(numero: 23),
                                          Places(numero: 22),
                                          Places(numero: 21)
                                        ]),
                                        Row(children: [
                                          Places(numero: 18),
                                          Places(numero: 17),
                                          Places(numero: 16)
                                        ]),
                                        Row(children: [
                                          Places(numero: 13),
                                          Places(numero: 12),
                                          Places(numero: 11)
                                        ]),
                                        Row(children: [
                                          Places(numero: 8),
                                          Places(numero: 7),
                                          Places(numero: 6)
                                        ]),
                                        Row(children: [
                                          PlacesReservees(numero: 3),
                                          PlacesReservees(numero: 2),
                                          PlacesReservees(numero: 1)
                                        ]),
                                        Row(children: [
                                          const SizedBox(width: 60),
                                          PlacesChauffeur()
                                        ]),
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
                                    const SizedBox(width: 150),
                                    Column(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 50,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/volant4_sf.png'),
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
    );
  }
}

// ── Widget Places ─────────────────────────────────────────────────────────────
class Places extends StatefulWidget {
  const Places({super.key, required this.numero});
  final int numero;

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
      ticket.place,
    );
  }

  List<bool> selection = List.filled(62, false);

  @override
  Widget build(BuildContext context) {
    // ── Mise à jour temps réel ─────────────────────────────────────────────
    // Si la place vient d'être achetée, elle apparaît dans maListeDeTickets
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
        margin: const EdgeInsets.all(0.5),
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
                    borderRadius: BorderRadius.circular(8)),
                child: SizedBox(
                  height: 35,
                  width: 35,
                  child: Center(
                    child: Text(
                      widget.numero.toString(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: const SizedBox(height: 19, width: 6),
              ),
            ),
            Positioned(
              right: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: const SizedBox(height: 19, width: 6),
              ),
            ),
            Positioned(
              top: -4,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: const SizedBox(height: 6, width: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets statiques ─────────────────────────────────────────────────────────
// ignore: must_be_immutable
class PlacesReservees extends StatelessWidget {
  PlacesReservees({super.key, required this.numero});
  final int numero;
  Color couleurSelection = const Color.fromARGB(166, 249, 195, 115);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: couleurSelection,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: SizedBox(
              height: 35,
              width: 35,
              child: Center(
                child: Text(numero.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Positioned(
              left: -3,
              child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: const SizedBox(height: 19, width: 6))),
          Positioned(
              right: -3,
              child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: const SizedBox(height: 19, width: 6))),
          Positioned(
              top: -4,
              child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: const SizedBox(height: 6, width: 26))),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class PlacesChauffeur extends StatelessWidget {
  PlacesChauffeur({super.key});
  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: Config.colors.vertB,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const SizedBox(
                height: 35,
                width: 35,
                child: Center(
                    child: Text("",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)))),
          ),
          Positioned(
              left: -3,
              child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: const SizedBox(height: 19, width: 6))),
          Positioned(
              right: -3,
              child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: const SizedBox(height: 19, width: 6))),
          Positioned(
              top: -4,
              child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: const SizedBox(height: 6, width: 26))),
        ],
      ),
    );
  }
}

Widget porte() {
  return Row(children: [
    Container(
        decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border.all(
                color: const Color.fromARGB(255, 89, 87, 87), width: 1)),
        height: 23,
        width: 8),
    Container(
        decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border.all(
                color: const Color.fromARGB(255, 89, 87, 87), width: 1)),
        height: 24,
        width: 10),
    Container(
        decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border.all(
                color: const Color.fromARGB(255, 89, 87, 87), width: 1)),
        height: 25,
        width: 12),
  ]);
}

void showRichTextDialog(BuildContext context, String nom, String telephone,
    String depart, String destination, int place) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(
          child: Text('$depart -> $destination',
              style: const TextStyle(
                  color: Color.fromARGB(255, 4, 20, 243), fontSize: 18)),
        ),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
            children: [
              const TextSpan(
                  text: 'Passager : ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              TextSpan(
                  text: '$nom\n', style: const TextStyle(color: Colors.black)),
              const TextSpan(
                  text: 'Téléphone : ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              TextSpan(
                  text: '$telephone\n',
                  style: const TextStyle(color: Colors.black)),
              const TextSpan(
                  text: 'Place :    ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              TextSpan(
                  text: '$place',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 4, 20, 243),
                      fontSize: 18)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK',
                style: TextStyle(color: Color.fromARGB(255, 4, 20, 243))),
          ),
        ],
      );
    },
  );
}
