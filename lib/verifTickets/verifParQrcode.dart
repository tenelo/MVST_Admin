
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mvst_admin/mesfonctions/mesfonctions.dart';

List<String> lecture = [];

class VerifParQrCode extends StatefulWidget {
  const VerifParQrCode({super.key});

  @override
  State<StatefulWidget> createState() => _VerifParQrCodeState();
}

class _VerifParQrCodeState extends State<VerifParQrCode> {
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
  );
  bool isScanning = false;
  bool qrRead = false;

  void stopScann() {
    if (isScanning) {
      controller.stop();
      setState(() {
        isScanning = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Config.colors.jauneBlanc),
        backgroundColor: Colors.blueGrey,
        title: Text(
          'Vérification',
          style: TextStyle(color: Config.colors.jauneBlanc),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Zone scanner ─────────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * .5,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) async {
                    if (!isScanning || qrRead) return;
                    final barcode = capture.barcodes.firstOrNull;
                    if (barcode?.rawValue == null) return;

                    setState(() => qrRead = true);

                    final ticketData =
                        TicketData.fromQrCode(barcode!.rawValue!);

                    final ticket = monTicket.firstWhereOrNull(
                      (ticket) => ticket.idDoc == ticketData.idTicket,
                    );

                    if (ticket != null) {
                      if (ticket.etatScanne == 'non') {
                        showDialog(
                          context: context,
                          builder: (context) => valide(context, ticketData),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => dejaValide(context, ticketData),
                        );
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => inValide(context, ticketData),
                      );
                    }
                  },
                ),
              ),
            ),
          ),

          // ── Indicateur de scan ───────────────────────────────────────────
          Expanded(
            child: isScanning
                ? Center(
                    child: CircularProgressIndicator(
                        color: Config.colors.jauneBlanc),
                  )
                : const SizedBox(),
          ),

          // ── Bouton Scanner ───────────────────────────────────────────────
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
                    isScanning = true;
                    qrRead = false;
                  });
                  await controller.start();
                }
              },
              child: Text('Scanner',
                  style: TextStyle(color: Config.colors.jauneBlanc)),
            ),
          ),

          // ── Bouton Arrêter ───────────────────────────────────────────────
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
              onPressed: stopScann,
              child: Text('Arrêter',
                  style: TextStyle(color: Config.colors.jauneBlanc)),
            ),
          ),

          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget valide(BuildContext context, TicketData ticketData) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset('assets/images/valide.png')),
          const SizedBox(height: 40),
          const Center(
            child: Text('TICKET VALIDE',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: _buildTicketContent(ticketData),
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
          Center(child: Image.asset('assets/images/dejaValide.png')),
          const SizedBox(height: 40),
          const Text('VALIDE DEJA SCANNE',
              style: TextStyle(
                  color: Color.fromARGB(255, 21, 162, 244),
                  fontWeight: FontWeight.bold)),
        ],
      ),
      content: _buildTicketContent(ticketData),
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
          Center(child: Image.asset('assets/images/invalide2.png')),
          const SizedBox(height: 40),
          const Center(
            child: Text('TICKET INVALIDE',
                style: TextStyle(
                    color: Color.fromARGB(255, 193, 27, 15),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: const Text(" "),
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

  // ── Contenu ticket réutilisable ──────────────────────────────────────────
  Widget _buildTicketContent(TicketData ticketData) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16.0),
        children: [
          _span('N° de Ticket : '),
          _value('${ticketData.idTicket}\n\n', fontSize: 12),
          _span('Départ du : '),
          _value('${ticketData.date}\n\n'),
          _span('Heure de départ : '),
          _value('${ticketData.heure} h\n\n'),
          _span('Destination : '),
          _value('${ticketData.destination}\n\n'),
          _span('Passager : '),
          _value('${ticketData.nom}\n\n'),
          _span('Siège : '),
          _value('${ticketData.place}\n\n'),
          _span('Téléphone : '),
          _value(ticketData.contact),
        ],
      ),
    );
  }

  TextSpan _span(String text) => TextSpan(
        text: text,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      );

  TextSpan _value(String text, {double fontSize = 16}) => TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize),
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
      etatScann: data[9].trim(),
    );
  }
}
