import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/screens/placesAssisesPE.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DepartsPlacesAssicesPourBtFlottant extends StatefulWidget {
  const DepartsPlacesAssicesPourBtFlottant({
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
  State<DepartsPlacesAssicesPourBtFlottant> createState() =>
      _DepartsPlacesAssicesPourBtFlottantState();
}

class _DepartsPlacesAssicesPourBtFlottantState
    extends State<DepartsPlacesAssicesPourBtFlottant> {
  List<Map<String, dynamic>> departs = [];
  bool _isLoading = true;

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
          if (mounted) {
            setState(() {
              departs = List<Map<String, dynamic>>.from(data['departs']);
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
        title: Text('Places occupées',
            style: TextStyle(
                color: Config.colors.authCardBackground, fontWeight: FontWeight.bold)),
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
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.blueGrey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Le ${widget.dateNormale}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text("Nombre de départs: ${departs.length}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        itemCount: departs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32.0),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlacesAssises(
                                        documentId: departs[index]
                                            ['documentId'],
                                        depart: departs[index]['depart'],
                                        destination: departs[index]
                                            ['destination'],
                                        heure: departs[index]['heureDeDepart'],
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Départ de ${departs[index]['heureDeDepart']} h",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Config.colors.bleuClaire),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
