import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

List<String> lecture = [];

class LecteurQrCode extends StatefulWidget {
  const LecteurQrCode({
    super.key,
    required this.gare,
    required this.uid,
    required this.dateAujourdhui,
    required this.dateApresDemain,
    required this.dateNormale,
  });
  final String gare;
  final String uid;
  final String dateAujourdhui;
  final String dateApresDemain;
  final String dateNormale;

  @override
  State<StatefulWidget> createState() => _LecteurQrCodeState();
}

class _LecteurQrCodeState extends State<LecteurQrCode> {
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    // Ne decoder que le QR : evite de tester tous les formats de
    // code-barres a chaque frame (gain de vitesse de decodage).
    formats: const [BarcodeFormat.qrCode],
    // Zoom automatique sur un QR detecte de loin : evite de devoir
    // rapprocher physiquement l'appareil.
    autoZoom: true,
    // Resolution plafonnee : un flux plus leger se decode plus vite
    // qu'une haute resolution native pensee pour l'apercu.
    cameraResolution: const Size(1280, 720),
    // Cadence de detection ramenee au defaut package (250ms) pour plus
    // de reactivite. N'affecte PAS le verrou anti-double-scan qrRead.
    detectionTimeoutMs: 250,
  );

  bool isScanning = false;
  bool qrRead = false;
  int compteurScans = 0;

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _connecterSocket();
    _demarrerScan();
  }

  @override
  void dispose() {
    controller.dispose();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  Future<void> _demarrerScan() async {
    await controller.start();
    if (mounted) setState(() => isScanning = true);
  }

  Future<void> _pauseScan() async {
    await controller.stop();
    if (mounted) setState(() => isScanning = false);
  }

  // Appelé après chaque dialog OK : reprend le scan sans réinitialiser la caméra
  void _continuerScan() {
    setState(() => qrRead = false);
  }

  // Cherche le ticket dans la liste préchargée, puis en fallback via PHP direct
  Future<Map<String, dynamic>?> _trouverTicket(TicketData ticketData) async {
    final trouve = listeDesTicketsScannes.firstWhereOrNull(
      (t) =>
          t['documentId']?.toString().trim() == ticketData.idTicket &&
          t['idUtilisateur']?.toString().trim() == ticketData.idUtilisateur &&
          int.tryParse(t['place'].toString()) == ticketData.place,
    );
    if (trouve != null) return trouve;

    // Fallback : requête directe par idUtilisateur
    try {
      final response = await http.post(
        apiUri('recuperation_mes_tickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idUtilisateur': ticketData.idUtilisateur}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tickets = List<Map<String, dynamic>>.from(data['tickets']);
          return tickets.firstWhereOrNull(
            (t) =>
                t['documentId']?.toString().trim() == ticketData.idTicket &&
                int.tryParse(t['place'].toString()) == ticketData.place,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  void _connecterSocket() {
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    socket.connect();
  }

  // Émet les événements Socket.IO pour que le client voie le changement en temps réel
  void _emettreTicketScanne(TicketData ticketData) {
    final dateAvecUnderscores = ticketData.date.replaceAll(' ', '_');
    final documentId =
        '${ticketData.depart}-${ticketData.destination}_${dateAvecUnderscores}_${ticketData.heure}_h';

    socket.emit('rejoindre_room', {
      'depart': ticketData.depart,
      'destination': ticketData.destination,
      'date': dateAvecUnderscores,
      'heure': ticketData.heure,
    });

    socket.emit('ticket_scanne', {
      'documentId': documentId,
      'idUtilisateur': ticketData.idUtilisateur,
      'place': ticketData.place,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: c.authBackground,
      appBar: AppBar(
        iconTheme: IconThemeData(color: c.jauneBlanc),
        backgroundColor: c.authBackground,
        title: Text(
          'Vérification Tickets',
          style: TextStyle(
            color: c.jauneBlanc,
            fontFamily: 'Lobster',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (compteurScans > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Text(
                    '$compteurScans scanné${compteurScans > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Zone scanner ──────────────────────────────────────────────────
          SizedBox(
            height: size.height * .50,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final Size zone = constraints.biggest;
                      // Cadre carre centre, 70% de la plus petite dimension (un QR est carre).
                      final double cote = (zone.shortestSide) * 0.70;
                      final Rect scanWindow = Rect.fromCenter(
                        center: zone.center(Offset.zero),
                        width: cote,
                        height: cote,
                      );
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            MobileScanner(
                              controller: controller,
                              scanWindow: scanWindow,
                              onDetect: (capture) async {
                                if (!isScanning || qrRead) return;
                                final barcode = capture.barcodes.firstOrNull;
                                if (barcode?.rawValue == null) return;

                                setState(() => qrRead = true);

                                final ticketData = TicketData.fromQrCode(
                                  barcode!.rawValue!,
                                );

                                final ticket = await _trouverTicket(ticketData);

                                if (!mounted) return;

                                if (ticket != null) {
                                  final String dateDuJour = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.now());
                                  final DateTime dateDuJourFormate =
                                      DateTime.parse(dateDuJour).toUtc();

                                  if (ticketData.dateCalcule.isAtSameMomentAs(
                                    dateDuJourFormate,
                                  )) {
                                    if (ticketData.etatScann == 'nonScanné') {
                                      // ── Socket d'abord → couleur change instantanément côté client
                                      _emettreTicketScanne(ticketData);

                                      if (!mounted) return;
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) =>
                                            _dialogValide(context, ticketData),
                                      );

                                      // PHP en arrière-plan pendant que l'admin lit le dialog
                                      misAjourEtatScanne(
                                        ticketData.idTicket,
                                        ticketData.idUtilisateur,
                                        ticketData.place,
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => _dialogDejaValide(
                                          context,
                                          ticketData,
                                        ),
                                      );
                                    }
                                  } else if (ticketData.dateCalcule.isAfter(
                                    dateDuJourFormate,
                                  )) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => _dialogFutureDate(
                                        context,
                                        ticketData,
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) =>
                                          _dialogInvalide(context, ticketData),
                                    );
                                  }
                                } else {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        _dialogInvalide(context, ticketData),
                                  );
                                }
                              },
                            ),
                            // Overlay visuel : cadre en equerre, cale sur le MEME scanWindow.
                            Positioned.fromRect(
                              rect: scanWindow,
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _CadreMirePainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Indicateur état scanner
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      constraints: const BoxConstraints(maxWidth: 200),
                      decoration: BoxDecoration(
                        color: isScanning
                            ? Colors.green.withValues(alpha: 0.8)
                            : Colors.orange.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isScanning
                                ? Icons.camera_alt_rounded
                                : Icons.pause_circle_outline,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isScanning ? 'En cours de scan...' : 'En pause',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          //const Spacer(),

          // ── Bouton Pause / Reprendre ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 70),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  foregroundColor: isScanning ? Colors.orange : Colors.green,
                  side: BorderSide(
                    color: isScanning ? Colors.orange : Colors.green,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isScanning ? _pauseScan : _demarrerScan,
                icon: Icon(
                  isScanning
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  isScanning ? 'Mettre en pause' : 'Reprendre le scan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  Widget _dialogValide(BuildContext context, TicketData ticketData) {
    return AlertDialog(
      title: _dialogTitre(
        'assets/images/valide.png',
        'TICKET VALIDE',
        Colors.green,
      ),
      content: _buildTicketContent(ticketData, Colors.green),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() => compteurScans++);
            _continuerScan();
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogDejaValide(BuildContext context, TicketData ticketData) {
    return AlertDialog(
      title: _dialogTitre(
        'assets/images/dejaValide.png',
        'DÉJÀ SCANNÉ',
        Colors.blue,
      ),
      content: _buildTicketContent(ticketData, Colors.blue),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _continuerScan();
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogFutureDate(BuildContext context, TicketData ticketData) {
    const couleur = Color.fromARGB(255, 134, 76, 17);
    return AlertDialog(
      title: _dialogTitre(
        'assets/images/sablier.png',
        'DATE ULTÉRIEURE',
        couleur,
      ),
      content: _buildTicketContent(ticketData, couleur),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _continuerScan();
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: couleur,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogInvalide(BuildContext context, TicketData ticketData) {
    const couleur = Color.fromARGB(255, 193, 27, 15);
    return AlertDialog(
      title: _dialogTitre(
        'assets/images/invalide2.png',
        'TICKET INVALIDE',
        couleur,
      ),
      content: const SizedBox.shrink(),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _continuerScan();
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: couleur,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogTitre(String asset, String texte, Color couleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(height: 80, width: 80, child: Image.asset(asset)),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            texte,
            style: TextStyle(
              color: couleur,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // ── Contenu ticket ──────────────────────────────────────────────────────────
  Widget _buildTicketContent(TicketData ticketData, Color accentColor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14.0),
        children: [
          _span('Ref : ', fontSize: 11),
          _value('${ticketData.idTicket}\n\n', fontSize: 7, color: Colors.grey),
          _span('Date départ : '),
          _value('${ticketData.date}\n\n'),
          _span('Heure : '),
          _value('${formatHeure(ticketData.heure)}\n\n'),
          _span('Trajet : '),
          _value('${ticketData.depart} → ${ticketData.destination}\n\n'),
          _span('Passager : '),
          _value('${ticketData.nom}\n\n'),
          _span('Tél : '),
          _value('${ticketData.contact}\n\n'),
          _span('Siège : '),
          TextSpan(
            text: '${ticketData.place}',
            style: TextStyle(
              color: accentColor,
              fontFamily: 'Lobster',
              fontSize: 38,
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _span(String text, {double fontSize = 13}) => TextSpan(
    text: text,
    style: TextStyle(
      color: Colors.grey[700],
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
    ),
  );

  TextSpan _value(
    String text, {
    double fontSize = 14,
    Color color = Colors.black87,
  }) => TextSpan(
    text: text,
    style: TextStyle(fontFamily: 'Lobster', fontSize: fontSize, color: color),
  );
}

class TicketData {
  final String idUtilisateur;
  final String idTicket;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String prix;
  final String etatScann;
  final DateTime dateCalcule;

  TicketData({
    required this.idUtilisateur,
    required this.idTicket,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.prix,
    required this.etatScann,
    required this.dateCalcule,
  });

  factory TicketData.fromQrCode(String qrCodeData) {
    final data = qrCodeData.split('\n');
    return TicketData(
      idUtilisateur: data[0].trim(),
      idTicket: data[1].trim(),
      place: int.tryParse(data[6].trim()) ?? -1,
      nom: data[2].trim(),
      contact: data[3].trim(),
      date: data[4].trim(),
      heure: data[5].trim(),
      depart: data[7].split('->')[0].trim(),
      destination: data[7].split('->')[1].trim(),
      prix: data[8].trim(),
      etatScann: data[9].trim(),
      dateCalcule: DateTime.parse(data[10].trim()),
    );
  }
}

class _CadreMirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final double l = size.shortestSide * 0.18; // longueur des equerres
    // Coin haut-gauche
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, l), paint);
    // Coin haut-droit
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - l, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), paint);
    // Coin bas-gauche
    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - l), paint);
    // Coin bas-droit
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - l, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
