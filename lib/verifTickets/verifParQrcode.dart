import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

List<String> lecture = [];

class VerifParQrCode extends StatefulWidget {
  const VerifParQrCode({super.key});

  @override
  State<StatefulWidget> createState() => _VerifParQrCodeState();
}

class _VerifParQrCodeState extends State<VerifParQrCode> {
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
        controller.scannedDataStream.listen((scanData) async {
          if (isScanning && !qrRead) {
            // Vérifier si le scanner est en cours et si aucun QR code n'a été lu
            setState(() {
              qrRead = true; // Un QR code a été lu
            });
            final ticketData = TicketData.fromQrCode(scanData.code!);

            // Chercher le ticket correspondant
            final ticket = monTicket.firstWhereOrNull(
              (ticket) => ticket.idDoc == ticketData.idTicket,
            );
            if (ticket != null) {
              if (ticket.etatScanne == 'non') {
                showDialog(
                  context: context,
                  builder: (context) {
                    return valide(context, ticketData);
                  },
                );
                /*
                await misAjourEtatScanne(
                    ticket.idDocParent, ticket.idDoc, "scanné");*/
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return dejaValide(context, ticketData);
                  },
                );
              }
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
                text: 'Heure de départ : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.heure} h\n\n',
            ),
            TextSpan(
                text: 'Destination : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.destination} \n\n',
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
      actions: [
        TextButton(
          onPressed: () {
            stopScann();
            setState(() {});
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
            child: Image.asset('assets/images/dejaValide.png'),
          ),
          const SizedBox(
            height: 40,
          ),
          const Text(
            'VALIDE DEJA SCANNE',
            style: TextStyle(
                color: Color.fromARGB(255, 21, 162, 244),
                fontWeight: FontWeight.bold),
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
                text: 'Heure de départ : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.heure} h\n\n',
            ),
            TextSpan(
                text: 'Destination : ',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            TextSpan(
              text: '${ticketData.destination} \n\n',
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
      actions: [
        TextButton(
          onPressed: () {
            stopScann();
            setState(() {});
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
            setState(() {});
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
