/* import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mvst/qrcode/creationQrCode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ticket_widget/ticket_widget.dart';
import 'package:ticket_widget/ticket_widget.dart';

class DetailsTicketsPdf extends StatelessWidget {
  const DetailsTicketsPdf({
    super.key,
    required this.id,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
  });

  final String id;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String etatScann;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Adjust as needed
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: 1,
            itemBuilder: (BuildContext context, int index) {
              return Center(
                child: TicketWidget(
                  width: MediaQuery.of(context).size.width * 0.80,
                  height: MediaQuery.of(context).size.height * 0.71,
                  padding: const EdgeInsets.all(16),
                  child: pw.TicketData(
                    id: id,
                    place: place,
                    nom: nom,
                    contact: contact,
                    date: date,
                    heure: heure,
                    depart: depart,
                    destination: destination,
                    etatScann: etatScann,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await generateAndSavePdf(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}

class TicketData extends pw.StatelessWidget {
  TicketData({
    Key? key,
    required this.id,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
  });

  final String id;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String etatScann;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Nom: $nom'),
        pw.Text('Place: $place'),
        pw.Text('Date: $date'),
        pw.Text('Heure: $heure'),

        // QR code
        pw.Center(
          child: pw.Container(
            width: 160,
            height: 160,
            child: pw.FittedBox(
              child: pw.CreationQrCode.buildQrCode(
                id,
                place,
                nom,
                contact,
                date,
                heure,
                depart,
                destination,
                etatScann,
              )!,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> generateAndSavePdf(BuildContext context) async {
  final pdf = pw.Document();

  // Add a page to the PDF document
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Container(
            width: MediaQuery.of(context as BuildContext).size.width * 0.80,
            height: MediaQuery.of(context as BuildContext).size.height * 0.71,
            child: pw.TicketWidget(
              width: MediaQuery.of(context as BuildContext).size.width * 0.80,
              height: MediaQuery.of(context as BuildContext).size.height * 0.71,
              padding: const pw.EdgeInsets.all(16),
              child:  TicketData(
                id: '123', // Example ID
                place: 1, // Example place
                nom: 'John Doe', // Example name
                contact: '+123456789', // Example contact
                date: '2022-04-16', // Example date
                heure: '09:00 AM', // Example time
                depart: 'City A', // Example departure
                destination: 'City B', // Example destination
                etatScann: 'scanned', // Example scan state
              ),
            ),
          ),
        );
      },
    ),
  );

  // Get the custom path for saving the PDF file
  final path = await getCustomPath();
  final uniquePdfPath = await getUniquePdfPath(path);

  // Save the PDF document to a file
  final File file = File(uniquePdfPath);
  await file.writeAsBytes(await pdf.save());

  // Show a message or inform the user that the PDF has been saved
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('PDF saved to: $uniquePdfPath'),
    ),
  );
}

Future<String> getCustomPath() async {
  final directory = await getApplicationDocumentsDirectory();
  final customPath = Directory('${directory.path}/monDossierPersonnalise');
  if (!await customPath.exists()) {
    await customPath.create(recursive: true);
  }
  return customPath.path;
}

Future<String> getUniquePdfPath(String directory) async {
  const baseName = 'monFichier.pdf';
  var file = File('$directory/$baseName');
  if (!await file.exists()) {
    return file.path;
  }
  int count = 1;
  while (await file.exists()) {
    final newFileName = '${baseName.replaceAll('.pdf', '')}_$count.pdf';
    count++;
    file = File('$directory/$newFileName');
  }
  return file.path;
}
 */