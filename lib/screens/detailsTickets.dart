import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst_admin/qrcode/creationQrCode.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ticket_widget/ticket_widget.dart';

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

  const DetailsTickets(
      {super.key,
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
      required this.datePourCalcule});
  @override
  _DetailsTicketsState createState() => _DetailsTicketsState();
}

class _DetailsTicketsState extends State<DetailsTickets> {
  // GENERER PDF
  Future<void> genererPDF(BuildContext context) async {
    // Générer QrCode
    final qrData =
        "${widget.idUtilisateur} \n${widget.idTicket} \n${widget.nom} \n${widget.contact} \n${widget.date} \n${widget.heure} \n${widget.place} \n${widget.depart}->${widget.destination} ";

    // Générer le QR Code en tant qu'image
    final QrPainter qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: couleurA,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: couleurB,
      ),
    );
    final qrImage = await qrPainter.toImage(280); // Taille du QR Code (200x200)

    // Convertir l'image en bytes
    final ByteData? byteData =
        await qrImage.toByteData(format: ImageByteFormat.png);
    final Uint8List imageData = byteData!.buffer.asUint8List();

    // Enregistrer l'image du QR Code en tant que fichier temporaire
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    final qrImagePath = '$tempPath/qr_code.png';

    final qrImageFile = File(qrImagePath);
    await qrImageFile.writeAsBytes(imageData);

    // Créer un nouveau document PDF
    final pdf = pw.Document();

    // Ajouter une page au document
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          // Ajout de la ligne pour créer l'image QR Code
          final pdfImage = pw.MemoryImage(imageData);
          // Contenu de la page PDF
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // les éléments du ticket
                // première ligne (MVST)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      height: 25.0,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(10.0),
                        border:
                            pw.Border.all(width: 1.0, color: PdfColors.green),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(2.0),
                        child: pw.Center(
                          child: pw.Text(' Mieux Vous Servir Transport ',
                              style:
                                  const pw.TextStyle(color: PdfColors.green)),
                        ),
                      ),
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'MVST',
                          style: pw.TextStyle(
                            fontSize: 20.0,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        "Ticket Ref° ${widget.idTicket.toUpperCase()}",
                        style: const pw.TextStyle(
                            fontSize: 7, color: PdfColors.grey),
                      )
                    ],
                  ),
                ),
                // deuxième ligne (depart / destination)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 20.0),
                  child: pw.Center(
                    child: pw.Text(
                      '${widget.depart} -> ${widget.destination}',
                      style: pw.TextStyle(
                        fontSize: 20.0,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 25.0),
                  //Ligne A
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Passager',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Contact',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ligne B
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      widget.nom,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black),
                    ),
                    pw.Text(
                      widget.contact,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 16.0),
                      child: pw.Text(
                        'Date de voyage',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 16.0),
                      child: pw.Text(
                        'Heure',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      widget.date,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      widget.heure,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8, top: 16.0),
                      child: pw.Text(
                        'Tarif : ${widget.prixTicket} f',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 16.0, right: 10),
                      child: pw.Text(
                        'Siège',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 18.0),
                      child: pw.Text(
                        widget.place.toString(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                // QR CODE
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(
                      top: 8.0,
                    ),
                    child: pw.SizedBox(
                      width: 200,
                      height: 200,
                      child: pw.Image(pdfImage),
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text(
                    'La compagnie MVST vous souhaite bon voyage!',
                    style: pw.TextStyle(
                        font: pw.Font.courier(),
                        fontItalic: pw.Font.timesItalic()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

// SAUVEGARDE
    Uint8List pdfData = await pdf.save();
    sauvegarderPdf(
        pdfData, 'ticket_du_${widget.date}_Place_${widget.place}.pdf');
  }

  Future<void> sauvegarderPdf(Uint8List pdfData, String nomDuFichier) async {
    // Demander les permissions de stockage
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // Obtenir le répertoire de stockage externe
    final directory = await getExternalStorageDirectory();
    final mvstDirectory = Directory('${directory!.path}/TICKETS MVST');
    //final mvstDirectory = Directory('${directory!.path}/TICKETS MVST');

    // Créer le répertoire s'il n'existe pas
    if (!await mvstDirectory.exists()) {
      await mvstDirectory.create(recursive: true);
    }

    // Créer un nouveau nom de fichier unique
    var fichier = nomDuFichier;
    var file = File('${mvstDirectory.path}/$fichier');
    int count = 1;
    while (await file.exists()) {
      final nouveauNom = '${nomDuFichier.replaceAll('.pdf', '')}_$count.pdf';
      fichier = nouveauNom;
      file = File('${mvstDirectory.path}/$fichier');
      count++;
    }
    // Définir le chemin du fichier
    final cheminFichier = '${mvstDirectory.path}/$fichier';

    // Enregistrer le fichier PDF
    final fic = File(cheminFichier);
    await fic.writeAsBytes(pdfData);
// Ouvrir le fichier PDF
    OpenFile.open(cheminFichier);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text(
          'PDF du ticket créé avec succès dans le repertoir : $cheminFichier',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text(
          'Details du ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: TicketWidget(
                width: MediaQuery.of(context).size.width * 0.84,
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(16),
                child: TicketData(
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
                  etatScann: widget.etatScann,
                  dateCalcule: widget.datePourCalcule,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // première ligne (MVST)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 25.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(width: 1.0, color: Colors.green),
              ),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Center(
                  child: Text(
                    ' Mieux Vous Servir Transport ',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
            ),
            const Row(
              children: [
                Text(
                  'MVST',
                  style: TextStyle(
                    color: Color.fromARGB(255, 10, 127, 229),
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
        // deuxième ligne
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                "Ticket Ref ${idTicket.toUpperCase()}",
                style: TextStyle(fontSize: 7, color: Colors.grey),
              )
            ],
          ),
        ),
        // deuxième ligne (depart / destination)
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Center(
            child: Text(
              '$depart -> $destination',
              style: const TextStyle(
                  color: Color.fromARGB(255, 9, 15, 123),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 25.0),
          //Ligne A
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passager',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                'Contact',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ),
        // Ligne B
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nom,
              style: const TextStyle(
                fontFamily: 'Lobster',
              ),
            ),
            Text(
              contact,
              style: const TextStyle(
                fontFamily: 'Lobster',
              ),
            ),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Date de voyage',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Heure',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Text(
              heure,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8, top: 16.0),
              child: Text(
                'Tarif : $prixTicket f',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0, right: 10),
              child: Text(
                'Siège',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
                    fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),
        // QR CODE
        Center(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 1.0,
            ),
            child: SizedBox(
              width: 180,
              height: 180,
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
