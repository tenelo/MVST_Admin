import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

List<String> validate = [
  "valide",
  "001",
  "ok",
  "yes",
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
            height: MediaQuery.of(context).size.height * .6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
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
            if (validate.contains(scanData.code)) {
              lecture.add(scanData.code!);
              showDialog(
                context: context,
                builder: (context) {
                  return valide(context, scanData.code!);
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return inValide(context, scanData.code!);
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

  Widget valide(BuildContext context, String donnees) {
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
            'TICKET VALIDE',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
          "Départ du: $donnees!\nA: $donnees\nSiège: $donnees\nPassager: $donnees"),
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

  Widget dejaValide(BuildContext context, String donnees) {
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
            'VALIDE DEJA SACANNER',
            style: TextStyle(
                color: Color.fromARGB(255, 2, 41, 125),
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
          "Départ du: $donnees!\nA: $donnees\nSiège: $donnees\nPassager: $donnees"),
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

  Widget inValide(BuildContext context, String donnees) {
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
          const Text(
            'TICKET INVALIDE',
            style: TextStyle(
                color: Color.fromARGB(255, 193, 27, 15),
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
          "Départ du: $donnees!\nA: $donnees\nSiège: $donnees\nPassager: $donnees"),
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
