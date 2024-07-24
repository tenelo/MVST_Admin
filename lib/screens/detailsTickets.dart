import 'package:flutter/material.dart';
import 'package:mvst_admin/qrcode/creationQrCode.dart';
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
      required this.prixTicket});
  @override
  _DetailsTicketsState createState() => _DetailsTicketsState();
}

class _DetailsTicketsState extends State<DetailsTickets> {

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
                ),
              ),
            ),
          ],
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
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                "Ticket N° ${idTicket.toUpperCase()}",
                style: TextStyle(fontSize: 9, color: Colors.grey),
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
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
                  fontSize: 16,
                  color: Colors.black),
            ),
            Text(
              heure,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black),
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
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0, right: 10),
              child: Text(
                'Siège',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
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
                    fontSize: 18,
                    color: Colors.black),
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
              width: 160,
              height: 160,
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
                  etatScann,
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
