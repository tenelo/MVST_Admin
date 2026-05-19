import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/screens/placesAssisesStandard.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LesDeparts extends StatefulWidget {
  const LesDeparts({
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
  State<LesDeparts> createState() =>
      _LesDepartsState();
}

class _LesDepartsState
    extends State<LesDeparts> {
  List<Map<String, dynamic>> departs = [];
  bool _isLoading = true;
  late DateTime _dateSelectionnee;
  late String _dateNormale;

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _dateSelectionnee = _parseDate(widget.date);
    _dateNormale = widget.dateNormale;
    _chargerDeparts();
    _connecterSocket();
  }

  DateTime _parseDate(String s) {
    try {
      return DateFormat('EEEE_d_MMMM_y', 'fr_FR').parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  String get _dateApi =>
      DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(_dateSelectionnee);

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
    socket.on('liste_mise_a_jour', (data) {
      if (data['depart'] == widget.gare) _chargerDeparts();
    });
  }

  Future<void> _chargerDeparts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.post(
        apiUri('departsParGare.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'date': _dateApi, 'gare': widget.gare}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            departs = List<Map<String, dynamic>>.from(data['departs']);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateSelectionnee = picked;
        _dateNormale = DateFormat('d MMMM yyyy', 'fr_FR').format(picked);
      });
      _chargerDeparts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vipCount = departs
        .where((d) =>
            (d['typeVoyage']?.toString().toLowerCase() ?? '') == 'vip')
        .length;
    final stdCount = departs.length - vipCount;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.authCardBackground),
        title: Text('Places occupées',
            style: TextStyle(
                color: Config.colors.authCardBackground,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_outlined,
                color: Config.colors.authCardBackground),
            onPressed: _choisirDate,
          ),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun départ trouvé pour le $_dateNormale',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Config.colors.authCardBackground,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Le $_dateNormale',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                    'Total : ${departs.length} départ${departs.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const Spacer(),
                                if (stdCount > 0)
                                  _TypeChip(
                                      label: 'Std $stdCount', isVip: false),
                                if (stdCount > 0 && vipCount > 0)
                                  const SizedBox(width: 6),
                                if (vipCount > 0)
                                  _TypeChip(
                                      label: 'VIP $vipCount', isVip: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: departs.length,
                        itemBuilder: (context, index) {
                          final d = departs[index];
                          final typeVoyage =
                              d['typeVoyage']?.toString() ?? 'standard';
                          final isVip = typeVoyage.toLowerCase() == 'vip';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: isVip
                                      ? const Color(0xFFB8860B)
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32.0),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlacesAssises(
                                        documentId: d['documentId'],
                                        depart: d['depart'],
                                        destination: d['destination'],
                                        heure: d['heureDeDepart'],
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isVip) ...[
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFD700), size: 16),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        "Départ de ${d['heureDeDepart']} h",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: isVip
                                                ? const Color(0xFFFFD700)
                                                : Config.colors.bleuClaire),
                                      ),
                                    ),
                                    if (isVip) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700)
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: const Color(0xFFFFD700),
                                              width: 0.5),
                                        ),
                                        child: const Text('VIP',
                                            style: TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isVip;
  const _TypeChip({required this.label, required this.isVip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
