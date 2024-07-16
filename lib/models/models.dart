import 'package:cloud_firestore/cloud_firestore.dart';

class ImageModel {
  final String id;
  final String url;
  final String titre; // Ajout du champ titre
  final String description;

  ImageModel({
    required this.id,
    required this.url,
    required this.titre,
    required this.description,
  });

  factory ImageModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ImageModel(
      id: doc.id,
      url: data['url'] ?? '',
      titre: data['titre'] ?? '', // Récupération du champ titre
      description: data['description'] ?? '',
    );
  }
}
