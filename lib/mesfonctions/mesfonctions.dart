import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst_admin/config/config.dart';
import 'package:mysql1/mysql1.dart';

List<MonTicket> monTicket = [];
List<Map<String, dynamic>> listeDesTicketsScannes = [];
List<int> listeDesPlacesOccupees = [];

class ListesDesTickets {
  static Future<List<Map<String, dynamic>>> ticketsAscanner() async {
    final MySqlConnection? conn = await Connexion.connexionDB();
    try {
      // Génère la date du jour au format 'yyyy-MM-dd'
      String dateDuJour =
          DateFormat('yyyy-MM-dd', 'fr_FR').format(DateTime.now());

      // Exécute la requête pour récupérer tous les tickets dont la date est supérieure ou égale à aujourd'hui
      var result = await conn!.query(
          'SELECT * FROM Tickets WHERE datePourCalcule >= ?', [dateDuJour]);

      List<Map<String, dynamic>> listeDesTicketsScannes =
          result.map((row) => row.fields).toList();

      return listeDesTicketsScannes;
    } catch (error) {
      return [];
    } finally {
      // Vérifier si conn n'est pas null avant de fermer la connexion
      if (conn != null) {
        await conn.close();
      }
    }
  }

// Récupérer la liste des tickets scannés dont la date est égale à la date du jour
  static Future<List<Map<String, dynamic>>> listeDesTicketsScannes(
      String date) async {
    final conn = await Connexion.connexionDB();
    try {
      var result = await conn.query(
          'SELECT * FROM Tickets WHERE etatScanne = ? AND date = ?',
          ['scanné', date]);

      List<Map<String, dynamic>> listeDesTicketsScannes =
          result.map((row) => row.fields).toList();

      return listeDesTicketsScannes;
    } catch (error) {
      return [];
    } finally {
      await conn.close();
    }
  }
}

class MonTicket {
  String idDocParent;
  String idDoc;
  String etatScanne;

  MonTicket({
    required this.idDocParent,
    required this.idDoc,
    required this.etatScanne,
  });
}

void listenForTicketChanges() {
  final collectionRef = FirebaseFirestore.instance.collection('tickets');

  // Écoute tous les changements dans la collection 'tickets'
  // ignore: unused_local_variable
  final subscription = collectionRef.snapshots().listen((snapshot) {
    snapshot.docChanges.forEach((change) {
      // Réagir à n'importe quel changement ici
      ListesDesTickets.ticketsAscanner;
    });
  });

  // Pour arrêter l'écoute lorsque nécessaire
  // subscription.cancel();
}

class ImageService {
  final CollectionReference _imagesCollection =
      FirebaseFirestore.instance.collection('images');

  Future<void> addImage(File imageFile, String description) async {
    try {
      // Upload the image to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('images/$fileName');
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      // Save the image info to Firestore
      await _imagesCollection.add({
        'url': downloadUrl,
        'description': description,
      });
    } catch (e) {
      print('Error adding image: $e');
    }
  }

  Future<void> updateImage(String id, String newDescription) async {
    try {
      await _imagesCollection.doc(id).update({'description': newDescription});
    } catch (e) {
      print('Error updating image: $e');
    }
  }

  Future<void> deleteImage(String id) async {
    try {
      DocumentSnapshot doc = await _imagesCollection.doc(id).get();
      String url = doc['url'];

      // Delete the image from Firebase Storage
      Reference storageReference = FirebaseStorage.instance.refFromURL(url);
      await storageReference.delete();

      // Delete the image info from Firestore
      await _imagesCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}

Future<void> misAjourEtatScanne(
    String _documentId, String idUtilisateur, int _place) async {
  final conn = await Connexion.connexionDB();
  try {
    // Mise à jour de la valeur du champ 'etatScanne' à 'scanné' si les trois champs correspondent
    await conn.query(
      'UPDATE Tickets SET etatScanne = ? WHERE documentId = ? AND idUtilisateur = ? AND place = ?',
      ['scanné', _documentId, idUtilisateur, _place],
    );
  } catch (e) {
    // Gérer l'erreur (par exemple, journaliser ou afficher une notification)
  } finally {
    await conn.close();
  }
}

class Calcule {
  static double tailleEcran(BuildContext ctx) {
    double screenWidth = MediaQuery.of(ctx).size.width;
    double screenHeight = MediaQuery.of(ctx).size.height;
    return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
  }
}
