import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

List<int> listeDesNummeros = [];

class FonctionListeDesPlaces {
  // fonction pour recuperer les places
  static Future<void> recup() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collection('tickets').get();
    //ListeDesPlaces.listeNummeros
    listeDesNummeros = snapshot.docs
        .map((doc) {
          final data = doc.data();
          return data['place'] as int?;
        })
        .where((place) => place != null)
        .map((place) => place!)
        .toList();
  }

  // fonction pour enregitrer les places
  static Future<void> enregistrerPlaces(List<int> places) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final collectionRef = _firestore.collection('tickets');

    for (final place in places) {
      await collectionRef.add({'place': place});
    }
  }
}

class ClasseListeDesPlaces {
  static void getTicketsStream() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    _firestore.collection('tickets').snapshots().listen((snapshot) {
      listeDesNummeros.clear();
      snapshot.docs.forEach((doc) {
        final data = doc.data();
        if (data['place'] != null) {
          //ListeDesPlaces.listeNummeros
          listeDesNummeros.add(data['place'] as int);
        }
      });
    });
    print(' LISTE DE getTicketsStream ${listeDesNummeros}');
  }
}

void listenForTicketChanges() {
  final collectionRef = FirebaseFirestore.instance.collection('tickets');

  // Écoute tous les changements dans la collection 'tickets'
  final subscription = collectionRef.snapshots().listen((snapshot) {
    snapshot.docChanges.forEach((change) {
      // Réagir à n'importe quel changement ici
      FonctionListeDesPlaces.recup();
    });
  });

  // Pour arrêter l'écoute lorsque nécessaire
  // subscription.cancel();
}

///////////////////////////

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
