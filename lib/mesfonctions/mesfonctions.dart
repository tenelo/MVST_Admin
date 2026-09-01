import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kbChannel = MethodChannel('com.app.mvst_admin/keyboard');
Future<void> keyboardAdjustResize() =>
    _kbChannel.invokeMethod('adjustResize').catchError((_) {});
Future<void> keyboardAdjustNothing() =>
    _kbChannel.invokeMethod('adjustNothing').catchError((_) {});

List<MonTicket> monTicket = [];
List<Map<String, dynamic>> listeDesTicketsScannes = [];
List<int> listeDesPlacesOccupees = [];

// ─── API base URL ─────────────────────────────────────────────────────────────
const String baseUrl = 'https://mvst.tenelo.cloud';
Uri apiUri(String path) => Uri.parse('$baseUrl/$path');

// ─── Tickets à scanner ────────────────────────────────────────────────────────
class ListesDesTickets {
  // Récupérer tous les tickets dont la date >= aujourd'hui
  static Future<List<Map<String, dynamic>>> ticketsAscanner(
    String gare,
    String profil,
  ) async {
    try {
      final Uri uri = profil == 'superadmin'
          ? apiUri('superadmin_ticketsAscanner.php')
          : apiUri('ticketsAscanner.php');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: profil == 'superadmin' ? null : jsonEncode({'gare': gare}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          listeDesTicketsScannes = List<Map<String, dynamic>>.from(
            data['tickets'],
          );
          return listeDesTicketsScannes;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Récupérer les tickets scannés pour une date donnée
  static Future<List<Map<String, dynamic>>> ticketsScannesPourDate(
    String date,
  ) async {
    try {
      final response = await http.post(
        apiUri('ticketsAscanner.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'date': date, 'etatScanne': 'scanné'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['tickets']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// ─── Modèle ticket ────────────────────────────────────────────────────────────
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

// ─── Mise à jour etatScanne via PHP ──────────────────────────────────────────
// Renvoie l'etat renvoye par le serveur : 'scanne' (ok), 'deja_scanne',
// 'introuvable', ou null si erreur reseau/timeout (on n'a pas pu savoir).
Future<String?> misAjourEtatScanne(
  String documentId,
  String idUtilisateur,
  int place,
) async {
  try {
    final response = await http
        .post(
          apiUri('misAjourEtatScanne.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'documentId': documentId,
            'idUtilisateur': idUtilisateur,
            'place': place,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['etat'] as String?;
    }
    return null;
  } catch (e) {
    return null; // reseau lent/coupe : on ne bloque pas, on ne sait juste pas
  }
}

// ─── Service images Firebase ──────────────────────────────────────────────────
class ImageService {
  final CollectionReference _imagesCollection = FirebaseFirestore.instance
      .collection('images');

  Future<void> addImage(File imageFile, String description) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = FirebaseStorage.instance.ref().child(
        'images/$fileName',
      );
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask;
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();
      await _imagesCollection.add({
        'url': downloadUrl,
        'description': description,
      });
    } catch (e) {}
  }

  Future<void> updateImage(String id, String newDescription) async {
    try {
      await _imagesCollection.doc(id).update({'description': newDescription});
    } catch (e) {}
  }

  Future<void> deleteImage(String id) async {
    try {
      DocumentSnapshot doc = await _imagesCollection.doc(id).get();
      String url = doc['url'];
      Reference storageReference = FirebaseStorage.instance.refFromURL(url);
      await storageReference.delete();
      await _imagesCollection.doc(id).delete();
    } catch (e) {}
  }
}

// ─── Formatage heure HH:mm ────────────────────────────────────────────────────
String formatHeure(String h) {
  final trimmed = h.trim();
  if (trimmed.contains(':')) {
    final parts = trimmed.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
  return '${trimmed.padLeft(2, '0')}:00';
}

// ─── Utilitaires ──────────────────────────────────────────────────────────────
class Calcule {
  static double tailleEcran(BuildContext ctx) {
    double screenWidth = MediaQuery.of(ctx).size.width;
    double screenHeight = MediaQuery.of(ctx).size.height;
    return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
  }
}

class ConvertirHeure {
  static String formatDate(String date) {
    DateFormat inputFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    DateTime parsedDate = inputFormat.parse(date);
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate);
  }

  static String formatDatePourCalcule(String date) {
    DateFormat inputFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    DateTime parsedDate = inputFormat.parse(date);
    return DateFormat('yyyy-MM-dd', 'fr_FR').format(parsedDate);
  }
}

Future<void> supprimerGareEtUid() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('gare');
    await prefs.remove('uid');
    await prefs.remove('role');
  } catch (e) {}
}

Future<String?> recupererRole() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? 'admin';
  } catch (e) {
    return 'admin';
  }
}

Future<String?> recupererGare(String idUtilisateur) async {
  try {
    final response = await http.post(
      apiUri('recupererGare.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idUtilisateur': idUtilisateur}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['gare'] as String;
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}

