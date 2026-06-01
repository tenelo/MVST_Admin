// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:mvst_admin/qrcode/creationQrCode.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:ticket_widget/ticket_widget.dart';
import 'package:http/http.dart' as http;

class DetailsTickets extends StatefulWidget {
  final String idTicket;
  final String idUtilisateur;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String etatScann;
  final String statut;
  final String prixTicket;
  final DateTime datePourCalcule;
  final String typeVoyage;

  const DetailsTickets({
    super.key,
    required this.idTicket,
    required this.idUtilisateur,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
    required this.statut,
    required this.prixTicket,
    required this.datePourCalcule,
    required this.typeVoyage,
  });

  @override
  _DetailsTicketsState createState() => _DetailsTicketsState();
}

class _DetailsTicketsState extends State<DetailsTickets> {
  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late io.Socket socket;
  late String etatScannActuel;
  late StreamController<String> _etatScannController;

  @override
  void initState() {
    super.initState();
    etatScannActuel = widget.etatScann;
    _etatScannController = StreamController<String>.broadcast();
    _rafraichirEtat();
    _connecterSocket();
  }

  @override
  void dispose() {
    _etatScannController.close();
    socket.off('ticket_valide');
    socket.offAny();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      final dateAvecUnderscores = widget.date.replaceAll(' ', '_');
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': dateAvecUnderscores,
        'heure': widget.heure,
      });
    });

    socket.connect();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final dateAvecUnderscores = widget.date.replaceAll(' ', '_');
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': dateAvecUnderscores,
        'heure': widget.heure,
      });
    });

    socket.on('ticket_valide', (data) {
      if (data['idUtilisateur']?.toString() == widget.idUtilisateur &&
          int.tryParse(data['place'].toString()) == widget.place) {
        if (mounted) {
          setState(() {
            etatScannActuel = 'scanné';
            _etatScannController.add('scanné');
          });
        }
      }
    });

    socket.onDisconnect((_) {});
  }

  // ── GÉNÉRER PDF ────────────────────────────────────────────────────────────
  Future<void> genererPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 14),
                Text('Création du PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final qrData =
          "${widget.idUtilisateur}\n${widget.idTicket}\n${widget.nom}\n${widget.contact}\n${widget.date}\n${widget.heure}\n${widget.place}\n${widget.depart}->${widget.destination}\n${widget.prixTicket}\n${widget.etatScann}\n${widget.datePourCalcule.toIso8601String().split('T')[0]}";

      final QrPainter qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: couleurA),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: couleurB,
        ),
      );

      final qrImage = await qrPainter.toImage(1024);
      final ByteData? byteData = await qrImage.toByteData(
        format: ImageByteFormat.png,
      );
      final Uint8List imageData = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final qrImageFile = File('${tempDir.path}/qr_code.png');
      await qrImageFile.writeAsBytes(imageData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context pdfContext) {
            final pdfImage = pw.MemoryImage(imageData);
            return pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── En-tête ──────────────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        height: 28,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(
                            width: 1,
                            color: PdfColors.green,
                          ),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: pw.Text(
                            'Mieux Vous Servir Transport',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 20,
                              color: PdfColors.green,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Text(
                        'MVST',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Ticket Ref° ${widget.idTicket.toUpperCase()}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.SizedBox(height: 14),

                  // ── Trajet ────────────────────────────────────────────
                  pw.Center(
                    child: pw.Text(
                      '${widget.depart}  => ${widget.destination}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // ── Passager / Contact ────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Passager',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Contact',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        widget.nom,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        widget.contact,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── Date / Heure ──────────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Date de voyage',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Heure',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        widget.date,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        widget.heure,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── Tarif / Siège ─────────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Tarif',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Siège',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${widget.prixTicket} FCFA',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        widget.place.toString(),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),

                  // ── QR Code ───────────────────────────────────────────
                  pw.Center(
                    child: pw.SizedBox(
                      width: 380,
                      height: 380,
                      child: pw.Image(pdfImage),
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // ── Pied de page ──────────────────────────────────────
                  pw.Row(
                    children: [
                      pw.Text(
                        'La compagnie MVST vous souhaite bon voyage !',
                        style: pw.TextStyle(
                          fontSize: 20,
                          font: pw.Font.courier(),
                          fontItalic: pw.Font.timesItalic(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final Uint8List pdfData = await pdf.save();

      if (mounted) Navigator.pop(context);

      await sauvegarderPdf(
        pdfData,
        'ticket_du_${widget.date}_Place_${widget.place}.pdf',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> sauvegarderPdf(Uint8List pdfData, String nomDuFichier) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final directory = await getExternalStorageDirectory();
    final mvstDirectory = Directory('${directory!.path}/TICKETS MVST');

    if (!await mvstDirectory.exists()) {
      await mvstDirectory.create(recursive: true);
    }

    var fichier = nomDuFichier;
    var file = File('${mvstDirectory.path}/$fichier');
    int count = 1;
    while (await file.exists()) {
      final nouveauNom = '${nomDuFichier.replaceAll('.pdf', '')}_$count.pdf';
      fichier = nouveauNom;
      file = File('${mvstDirectory.path}/$fichier');
      count++;
    }

    final cheminFichier = '${mvstDirectory.path}/$fichier';
    final fic = File(cheminFichier);
    await fic.writeAsBytes(pdfData);
    OpenFile.open(cheminFichier);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text(
          'PDF créé avec succès : $cheminFichier',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _rafraichirEtat() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/etatTicket.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'documentId': widget.idTicket,
              'place': widget.place,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            etatScannActuel = data['etatScanne'];
            _etatScannController.add(etatScannActuel);
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.colors.authDialogBackground,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        title: const Text(
          'Details du ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Config.colors.authDialogBackground,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: TicketWidget(
                width: MediaQuery.of(context).size.width * 0.90,
                height: MediaQuery.of(context).size.height * 0.78,
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<String>(
                  stream: _etatScannController.stream,
                  initialData: etatScannActuel,
                  builder: (context, snapshot) {
                    return TicketData(
                      idUtilisateur: widget.idUtilisateur,
                      idTicket: widget.idTicket,
                      place: widget.place,
                      nom: widget.nom,
                      contact: widget.contact,
                      date: widget.date,
                      heure: widget.heure,
                      depart: widget.depart,
                      destination: widget.destination,
                      prixTicket: widget.prixTicket,
                      etatScann: snapshot.data ?? etatScannActuel,
                      dateCalcule: widget.datePourCalcule,
                      typeVoyage: widget.typeVoyage,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => genererPDF(context),
        child: const Text(
          'Imprimer',
          style: TextStyle(
            color: Color.fromARGB(255, 10, 127, 229),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── TicketData ─────────────────────────────────────────────────────────────────
class TicketData extends StatelessWidget {
  const TicketData({
    super.key,
    required this.idUtilisateur,
    required this.idTicket,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
    required this.prixTicket,
    required this.dateCalcule,
    required this.typeVoyage,
  });

  final String idUtilisateur;
  final String idTicket;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String prixTicket;
  final String etatScann;
  final DateTime dateCalcule;
  final String typeVoyage;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Première ligne (MVST + badge VIP) ─────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                height: 25.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(width: 1.0, color: Colors.green),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Center(
                    child: Text(
                      ' Mieux Vous Servir Transport ',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: w * 0.027,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (typeVoyage == 'vip') ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.020,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '★ VIP',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: w * 0.023,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'MVST',
                  style: TextStyle(
                    color: Color.fromARGB(255, 10, 127, 229),
                    fontSize: w * 0.051,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        // ── Référence ticket ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Ticket Ref ${idTicket.toUpperCase()}",
            style: const TextStyle(fontSize: 7, color: Colors.grey),
          ),
        ),
        // ── Départ / Destination ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Center(
            child: Text(
              '$depart -> $destination',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 15, 123),
                fontSize: w * 0.046,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // ── Passager / Contact ─────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passager',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Contact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nom, style: const TextStyle(fontFamily: 'Lobster')),
            Text(contact, style: const TextStyle(fontFamily: 'Lobster')),
          ],
        ),
        // ── Date / Heure ───────────────────────────────────────────────────
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Date de voyage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Heure',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              heure,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // ── Tarif / Siège ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 16.0),
              child: Text(
                'Tarif : $prixTicket f',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0, right: 10),
              child: Text(
                'Siège',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: Text(
                "$place",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // ── QR Code ────────────────────────────────────────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: SizedBox(
              width: w * 0.50,
              height: w * 0.50,
              child: FittedBox(
                child: CreationQrCode.buildQrCode(
                  idUtilisateur,
                  idTicket,
                  place,
                  nom,
                  contact,
                  date,
                  heure,
                  depart,
                  destination,
                  prixTicket,
                  etatScann,
                  dateCalcule,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'La compagnie MVST vous souhaite bon voyage!',
            style: TextStyle(fontFamily: 'Lobster'),
          ),
        ),
      ],
    );
  }
}
