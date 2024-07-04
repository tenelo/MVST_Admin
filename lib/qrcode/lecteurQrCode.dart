import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

List<String> validate = [
  "valide",
  "001",
  "ok",
  "7XQzur9d158OQFOfWVfB",
  "yes",
  "VcJliO5AMQJoZ1Tiv7jJ",
];

List<String> lecture = [];

class LecteurQrCode extends StatefulWidget {
  const LecteurQrCode({super.key});

  @override
  State<StatefulWidget> createState() => _LecteurQrCodeState();
}

class _LecteurQrCodeState extends State<LecteurQrCode> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool isScanning =
      false; // Ajout d'un booléen pour indiquer si le scanner est en cours ou non
  bool qrRead = false; // Booléen pour indiquer si un QR code a été lu

  void stopScann() async {
    if (isScanning) {
      setState(() {
        isScanning = false; // Arrêt du scan
      });
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Config.colors.jauneBlanc,
        ),
        backgroundColor: Colors.blueGrey,
        title: Text(
          'Vérification',
          style: TextStyle(color: Config.colors.jauneBlanc),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .5,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: _buildQrView(context),
            ),
          ),
          Expanded(
            child: isScanning
                ? Center(
                    child: CircularProgressIndicator(
                      color: Config.colors.jauneBlanc,
                    ),
                  )
                : const SizedBox(),
          ),
          Container(
            width: MediaQuery.of(context).size.width * .5,
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: BorderSide(color: Config.colors.jauneBlanc, width: 2.0),
                ),
                backgroundColor: Colors.transparent,
              ),
              onPressed: () async {
                if (!isScanning) {
                  setState(() {
                    isScanning = true; // Début du scan
                    qrRead =
                        false; // Réinitialiser le booléen de lecture de QR code
                  });
                  await controller?.resumeCamera();
                }
              },
              child: Text(
                'Scanner',
                style: TextStyle(
                  color: Config.colors.jauneBlanc,
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * .5,
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: BorderSide(color: Config.colors.jauneBlanc, width: 2.0),
                ),
                backgroundColor: Colors.transparent,
              ),
              onPressed: () async {
                stopScann();
              },
              child: Text(
                'Arrêter',
                style: TextStyle(
                  color: Config.colors.jauneBlanc,
                ),
              ),
            ),
          ),
          Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 250.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: (controller) {
        this.controller = controller;
        controller.scannedDataStream.listen((scanData) {
          if (isScanning && !qrRead) {
            // Vérifier si le scanner est en cours et si aucun QR code n'a été lu
            setState(() {
              qrRead = true; // Un QR code a été lu
            });
            final ticketData = TicketData.fromQrCode(scanData.code!);
            //if (validate.contains(scanData.code)) {
            if (validate.contains(ticketData.idTicket)) {
              lecture.add(scanData.code!);
              showDialog(
                context: context,
                builder: (context) {
                  return valide(context, ticketData);
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return inValide(context, ticketData);
                },
              );
            }
          }
        });
      },
      overlay: QrScannerOverlayShape(
          borderColor: Config.colors.jauneBlanc,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas d\'autorisation')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget valide(BuildContext context, TicketData ticketData) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset('assets/images/valide.png'),
          ),
          const SizedBox(
            height: 40,
          ),
          Center(
            child: const Text(
              'TICKET VALIDE',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.0,
          ),
          children: <TextSpan>[
            TextSpan(
                text: 'N° de Ticket : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.idTicket}\n\n',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextSpan(
                text: 'Départ du : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.date}\n\n',
            ),
            TextSpan(
                text: 'heure de départ : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.heure} h\n\n',
            ),
            TextSpan(
                text: 'Passager : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.nom}\n\n',
            ),
            TextSpan(
                text: 'Siège : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.place}\n\n',
            ),
            TextSpan(
                text: 'Téléphone : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.contact}',
            ),
          ],
        ),
      ),
      /* Text(
          "N° de Ticket : ${ticketData.idTicket}\nDépart du : ${ticketData.date}\nà : ${ticketData.heure} h\nPassager: ${ticketData.nom}\nTéléphone: ${ticketData.contact}\nSiège: ${ticketData.place}"), */
      actions: [
        TextButton(
          onPressed: () {
            stopScann();
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget dejaValide(BuildContext context, TicketData ticketData) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset('assets/images/valide.png'),
          ),
          const SizedBox(
            height: 40,
          ),
          const Text(
            'VALIDE DEJA SCANNE',
            style: TextStyle(
                color: Color.fromARGB(255, 2, 41, 125),
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
          "N° de Ticket : ${ticketData.idTicket}\nDépart du: ${ticketData.date}\nA: ${ticketData.heure}\nPassager: ${ticketData.nom}\Téléphone: ${ticketData.contact}\nSiège: ${ticketData.place}"),
      actions: [
        TextButton(
          onPressed: () {
            stopScann();
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget inValide(BuildContext context, TicketData ticketData) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset('assets/images/invalide2.png'),
          ),
          const SizedBox(
            height: 40,
          ),
          Center(
            child: const Text(
              'TICKET INVALIDE',
              style: TextStyle(
                  color: Color.fromARGB(255, 193, 27, 15),
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(" "),
      actions: [
        TextButton(
          onPressed: () {
            stopScann();
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
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
  final String etatScann;

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
    required this.etatScann,
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
      etatScann: data[8].trim(),
    );
  }
}


// CREATION QR CODE

/*

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst/config/config.dart';
import 'package:qr_flutter/qr_flutter.dart';

Color? couleurA;
Color? couleurB;

class CreationQrCode {
  static Widget buildQrCode(
    final String idUtilisateur,
    final String idTicket,
    final int place,
    final String nom,
    final String contact,
    final String date,
    final String heure,
    final String depart,
    final String destination,
    final String etatScann,
  ) {
    final String message =
        "$idUtilisateur \n$idTicket \n$nom \n$contact \n$date \n$heure \n$place \n$depart->$destination \n$etatScann";

    final FutureBuilder<ui.Image> qrFutureBuilder = FutureBuilder<ui.Image>(
      future: _loadOverlayImage(),
      builder: (BuildContext ctx, AsyncSnapshot<ui.Image> snapshot) {
        const double size = 280.0;
        if (snapshot.hasData) {
          //return const SizedBox(width: size, height: size);
          if (etatScann == "scanne") {
            couleurA = Config.colors.bleuA;
            couleurB = Config.colors.bleuB;
          } else {
            couleurA = Config.colors.vertA;
            couleurB = Config.colors.vertB;
          }
        }

        return CustomPaint(
          size: const Size.square(size),
          painter: QrPainter(
            data: message,
            version: QrVersions.auto,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: couleurA,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: couleurB,
            ),
            embeddedImage: snapshot.data,
            // taille de l'image dans le qrcode
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size.square(75),
            ),
          ),
        );
      },
    );

    return qrFutureBuilder;
  }

  static Future<ui.Image> _loadOverlayImage() async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ByteData byteData = await rootBundle.load('assets/images/Qr_rd3.png');
    ui.decodeImageFromList(byteData.buffer.asUint8List(), completer.complete);
    return completer.future;
  }
}


*/