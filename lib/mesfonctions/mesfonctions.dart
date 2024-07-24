import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

List<MonTicket> monTicket = [];

class ListeDesId {
// Fonction pour récupérer un stream de tickets avec une date de départ spécifique
  static Future<void> getTicketsAScanner(String date) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Requête Firestore pour obtenir les documents avec la date de départ spécifiée
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
        .collection('tickets')
        .where('dateDeDepart', isEqualTo: date)
        .get();

    // Parcourir les documents récupérés
    for (var doc in querySnapshot.docs) {
      // Récupérer la sous-collection 'sousCollectionTickets' pour chaque document
      QuerySnapshot<Map<String, dynamic>> subcollectionSnapshot =
          await doc.reference.collection('sousCollectionTickets').get();

      // Extraire les ID des documents de la sous-collection et les ajouter à l'ensemble
      for (var subDoc in subcollectionSnapshot.docs) {
        monTicket.add(MonTicket(
            idDocParent: doc.id,
            idDoc: subDoc.id,
            etatScanne: subDoc['etatScanne']));
      }
    }
  }
}

/*
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>>
      recuperationDeMesTickets() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .asyncMap((ticketsSnapshot) async {
      List<DocumentSnapshot<Map<String, dynamic>>> allDocuments = [];
      for (var ticketDoc in ticketsSnapshot.docs) {
        try {
          var subcollectionSnapshot = await ticketDoc.reference
              .collection('sousCollectionTickets')
              .where('idUtilisateur', isEqualTo: widget.idUtilisateur)
              .orderBy('dateDeCreation', descending: true)
              .get();
          allDocuments.addAll(subcollectionSnapshot.docs);
        } catch (e) {
          print('Erreur de chargement du ticket ${ticketDoc.id}: $e');
        }
      }
      return allDocuments;
    });
  }

*/

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
  final subscription = collectionRef.snapshots().listen((snapshot) {
    snapshot.docChanges.forEach((change) {
      // Réagir à n'importe quel changement ici
      ListeDesId.getTicketsAScanner;
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
    String idDocParent, String docId, String _etat) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try {
    await _firestore
        .collection('tickets')
        .doc(idDocParent)
        .collection('sousCollectionTickets')
        .doc(docId)
        .update({
      'etatScanne': _etat,
      'heureDeScanne': FieldValue.serverTimestamp(),
    });
  } catch (e) {}
}
