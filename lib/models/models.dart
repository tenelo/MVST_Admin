import 'package:cloud_firestore/cloud_firestore.dart';

List<int> listeDesNummeros = [];

class FonctionListeDesPlaces {
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
    print(' LISTE DE recup() ${listeDesNummeros}');
  }
}

class ListeDesPlaces {
  static List<int> listeNummeros = [];
}

class ClasseListeDesPlaces {
  static void getTicketsStream() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    _firestore.collection('tickets').snapshots().listen((snapshot) {
      ListeDesPlaces.listeNummeros.clear();
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
